require 'rserve'
require 'timeout'
require 'matrix'  # seems to be required under the hood by rserve gem

# R server wrapper
#
# The purpose of this class is to allow us to easily send R commands to the R server, process and return the results.
#
# R.exec is the key entry point
class R
  # Execute a block of R commands, using optional syntactic sugar, returning the results
  #
  # Creates a new connection to the RServe after every connection.
  #
  # Example:
  # 
  # require 'r'
  # 
  # R.exec do
  #   a 'x', 2
  #   a 'y', 4
  #   ve 'x = -x'
  #   xy = e "x + y"
  #   xdivy = e "x / y"
  #   [xy, xdivy]
  # end 
  # => [2, -0.5]
  #
  def self.exec args={}, &block
    raise "Expected hash, keys will be defined as R variable names, example: {xvals: [1,2,3], yvals: [3,2,1]}" unless args.is_a?(Hash)
    begin
      conn = Rserve::Connection.new
      dsl = R::RserveConnectionDsl.new conn, args
      res = dsl.instance_eval &block
      dsl.clear   # since connection is recycled, make an attempt to clean up all defined vars
      return res
    rescue => e
      conn = dsl = nil    # ensure cleanup
      raise e
    end
  end

  # defines nice dsl for working with rserve-client
  class RserveConnectionDsl
    attr_accessor :conn, :args, :pkg_dir

    def initialize conn, args={}
      self.conn = conn
      self.args = args
      self.pkg_dir ||= args.delete(:pkg_dir)
      self.pkg_dir ||= File.join(Rails.root, '/r-packages') if defined?(Rails)
      self.pkg_dir ||= 'r-packages'      
      args.each{|k,v| a(k.to_s, v)} if args.any?
    end

    def do_conn meth, *args
      conn.send(meth, *args)
    end

    def assert_defined *keys
      keys.map do |k|
        begin
          e k.to_s
        rescue
          raise ArgumentError.new("expected #{k} to be defined in R envionment, but was not")
        end
      end
    end

    # short for 'eval', execute given arguments, collect results, convert to ruby
    def e *args
      do_conn(:eval, *args).to_ruby
    end

    # short for 'void_eval', just execute the arguments, don't return results
    def ve *args
      do_conn :void_eval, *args
    end

    # short for 'assign', send ruby objects to r, save as variable
    def a *args
      args[1] = args[1].to_s if args[1].is_a?(Symbol)
      do_conn :assign, *args
    end

    def package_installed? pkgname
      e "('#{pkgname}' %in% rownames(installed.packages()) == TRUE)"
    end

    def installed_packages
      e "rownames(installed.packages())"
    end

    def install_package pkgname
      FileUtils.mkdir_p pkg_dir

      unless package_installed? pkgname
        ve "install.packages('#{pkgname}', repos='http://cran.cnr.Berkeley.edu/', depends=c('Depends'))"
      end        
    end

    # attempts to install given R package if necessary and require in the environment via 'library'
    def library pkgname, fail_after=300
      Timeout::timeout(fail_after) do
        install_package pkgname
        e "library(#{pkgname})"
      end
    end

    # remove defined variables from the R environment
    def clear
      ve 'rm(list=ls())'
    end
  end
end