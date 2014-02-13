require 'pry'
require_relative '../../lib/rsugar'

describe R do
  let(:conn) { Rserve::Connection.new }
  let(:dsl) { R::RserveConnectionDsl.new conn }

  before do
    FileUtils.rm_rf(dsl.pkg_dir) if File.exist?(dsl.pkg_dir)
  end
  
  it 'should execute R language statements using the DSL, and return results' do
    R.exec do
      a 'x', 2
      a 'y', 4
      ve 'x = -x'
      xy = e "x + y"
      xdivy = e "x / y"
      [xy, xdivy]
    end.should == [2, -0.5]
  end

  it 'should accept an optional hash of values, assign to named R values' do
    R.exec({xvals: [1,2,3,4], yvals: [4,3,2,1]}) do
      e 'xvals + yvals'
    end.should == [5,5,5,5]
  end

  it 'should convert assigned values to string if they are symbol to prevent Rserve exceptions' do
    R.exec({foobar: :stuff}){ e('foobar') }.should == 'stuff'
  end

  it 'should clean up defined R variables after block exists' do
    R.exec { a 'x', 1 }
    expect do
      R.exec { e('x') }
    end.to raise_error(Rserve::Connection::EvalError)
  end

  describe R::RserveConnectionDsl do
    let(:pkgname) { "base" }

    it 'should expose Rserve methods with shorter syntactic sugar accessors' do
      val = "1"
      return_val = Rserve::REXP::Integer.new 1
      {eval: :e, assign: :a, void_eval: :ve}.each do |rserve_method, sugar|
        conn.should_receive(rserve_method).with(val).and_return(return_val)
        dsl.send(sugar, val)
      end
    end

    it '#assert_defined should raise if given variables do not exist in R' do
      dsl.a 'x', 2
      dsl.assert_defined('x')
      expect { dsl.assert_defined('y') }.to raise_error(ArgumentError)
    end

    it '#clear should remove bound variables from R environment (to the extent R allows this)' do
      dsl.should_receive(:ve).with('rm(list=ls())')
      dsl.clear
    end

    context 'package management' do
      it '#installed_packages should return a list of installed R packages available on the server' do
        dsl.installed_packages.should include("base")
      end

      it '#package_installed? should return true if specified package installed, false if not' do
        dsl.package_installed?("base").should be_true
        dsl.package_installed?("foobar").should be_false
      end
    end

    context '#install_package' do
      let(:do_install) { dsl.install_package(pkgname) }

      it 'should -attempt- to install missing R library and all dependencies if it doesnt exist (dicey)' do
        dsl.should_receive(:package_installed?).and_return(false)
        dsl.should_receive(:ve).with("install.packages('#{pkgname}', repos='http://cran.cnr.Berkeley.edu/', depends=c('Depends'))")
        do_install
      end

      it 'should not attempt to install if library already exists' do
        dsl.should_receive(:package_installed?).and_return(true)
        dsl.should_not_receive(:ve)
        do_install
      end

      it 'should create a directory to store R packages if it doesnt already exist' do
        File.exist?(dsl.pkg_dir).should be_false
        do_install
        File.exist?(dsl.pkg_dir).should be_true
      end
    end

    context '#library' do
      let(:do_library) { dsl.library(pkgname) }

      it 'should install package if it doesnt exist and require R library' do
        dsl.should_receive(:package_installed?).and_return(false)
        dsl.should_receive(:e).with("library(#{pkgname})")
        do_library
      end

      it 'should just require the package via R library function if it exists' do
        dsl.should_receive(:package_installed?).and_return(true)
        dsl.should_receive(:e).with("library(#{pkgname})")
        do_library
      end

      it 'should actually do all this outside of stubs' do
        dsl.library('xtable')
        dsl.e 'd <- data.frame(col1=c(1,2,3))'
        dsl.e('xtable(d)').should == [[1.0, 2.0, 3.0]]
      end
    end
  end
end
