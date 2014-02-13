# Rsugar

RSugar allows you to execute R language commands from Ruby.  It wraps rserve_client gem, providing some syntactic sugar and a few helper methods.

## Installation

Install rserve:

    http://www.rforge.net/Rserve/doc.html

Add this line to your application's Gemfile:

    gem 'rsugar'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rsugar

## Usage

RSugar allows you to execute R language code on a seperate RServe.  It is essentially a wrapper that provides some nice sugar and block style execution for the rserve_client gem.

R.exec is the main entry point.  You pass it a block, within which you have access to a few methods corresponding directly to the RServe gem API:

    a - assign
    e - eval
    ve - void eval

assign serializes the given Ruby object, sends it over to Rserve.  eval sends a given string to Rserve, executes it, and returns the result.  void eval executes the string on Rserve, but does not return the results.

```ruby
require 'rsugar'

R.exec do
  a 'x', 2
  a 'y', 4
  ve 'x = -x'
  xy = e "x + y"
  xdivy = e "x / y"
  [xy, xdivy]
end 
=> [2, -0.5]
```

You can optionally pass a hash of Ruby objects, which will automatically be passed and initialized in the R environment.

```ruby
R.exec({xvals: [1,2,3,4], yvals: [4,3,2,1]}) do
  e 'xvals + yvals'
end
=> [5,5,5,5]
```

### Packages

Finally, you can ask rserver to use specific R packages.

```ruby
R.exec do
  library('xtable')
  e 'd <- data.frame(col1=c(1,2,3))'
  e('xtable(d)')
end.to_a
=> [[1.0, 2.0, 3.0]]
```

The 'library' method also tries to install the package for you if it doesn't exist.  This requires the creation of an r-packages directory, and is somewhat dicey, since it can fail for a number of reasons (network connectivity, inability of R to install dependant packages, for example).

For production systems, it's recommended you manually install R packages first.

#### Default locations:

Environment | Location
Rails defined? | File.join(Rails.root, 'r-packages')
Rails not defined? | './r-packages'

### Note:

There are some ramifications to using R this way, the first is that its sloooooow, since Ruby objects have to be serialized, transmitted over rserve's wire protocol, executed and round-tripped back to the Ruby process.

In addition, each time R.exec is called, it creates a seperate connection to rserver, via Rserve::Connection.new.  After the block returns, this connection should be freed/garbage collected.  There is probably some not insignificant overhead with this, but you probably won't run into issues unless you're calling R.exec dozens or hundreds of times in an inner loop.  Which is a bad idea anyway since rserver is sloooooow.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
