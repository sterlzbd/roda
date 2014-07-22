Sinuba
======

Sinuba is a microframework for web development, inspired by Cuba
and Sinatra.

Installation
------------

``` console
$ gem install sinuba
```

Resources
---------

* Website: http://sinuba.jeremyevans.net
* Source: http://github.com/jeremyevans/sinuba
* Bugs: http://github.com/jeremyevans/sinuba/issues
* Google Group: http://groups.google.com/group/ruby-sinuba
* IRC: irc://chat.freenode.net/#sinuba

Usage
-----

Here's a simple application:

``` ruby
# cat config.ru
require "sinuba"

Sinuba.use Rack::Session::Cookie, :secret => "__a_very_long_string__"

Sinuba.route do |r|
  r.get do
    r.on "hello" do
      "Hello world!"
    end

    r.on :root=>true do
      r.redirect "/hello"
    end
  end
end

run Sinuba.app
```

You can now run `rackup` and enjoy what you have just created.

Here's a breakdown of what is going on in the above block:

The `route` block is called whenever a new request comes in, 
and it is yieled an instance of a subclass of `Rack::Request`
that uses `Sinuba::RequestMethods`, which handles matching
routes.  By convention, this argument should be named `r`.

The primary way routes are matched in Sinuba is by calling
`r.on`, or a method like `r.get` which calls `r.on`.  `r.on`
takes each of the arguments given and tries to match them to
the current request.  If it is able to successfully match
them, it yields to the `r.on` block, otherwise it returns
immediately.  If you want a block to always run, you can call
`r.on` with no arguments.

If `r.on` matches and control is yielded to the block, whenever
the block returns, the response will be returned.  If the block
returns a string, it will interpreted as the body for the
response.

`r.redirect` immediately returns the response, allowing for
code such as `r.redirect(path) if some_condition`.

The `.app` at the end is an optimization, which you can leave
off, but which saves a few methods call for every response.

Subclasses
----------

In general, it's not recommended to use the Sinuba class directly
as displayed above.  Instead, it's better to subclass Sinuba. You
can do this the standard way:

``` ruby
# cat config.ru
require "sinuba"

class App < Sinuba
end

App.use Rack::Session::Cookie, :secret => "__a_very_long_string__"

App.route do |r|
  r.get do
    r.on "hello" do
      "Hello world!"
    end

    r.on :root=>true do
      r.redirect "/hello"
    end
  end
end

run App.app
```

Or you can use the `Sinuba.define` method:

``` ruby
# cat config.ru
require "sinuba"

run(Sinuba.define do
  use Rack::Session::Cookie, :secret => "__a_very_long_string__"

  route do |r|
    r.get do
      r.on "hello" do
        "Hello world!"
      end

      r.on :root=>true do
        r.redirect "/hello"
      end
    end
  end
end.app)
```

`Sinuba.define` creates an anonymous subclass of Sinuba, and
`class_eval`s the block in the context of the subclass. So any
methods you define in the `define` block are available as
instance methods inside the route block.

Matchers
--------

Here's an example showcasing how different matchers work:

``` ruby
require "sinuba"

Sinuba.define do
  use Rack::Session::Cookie, :secret => "__a_very_long_string__"

  route do |r|
    # only GET requests
    r.get do

      # /
      r.on :root=>true do
        "Home"
      end

      # /about
      r.on "about" do
        "About"
      end

      # /styles/basic.css
      r.on "styles", :extension => "css" do |file|
        "Filename: #{file}" #=> "Filename: basic"
      end

      # /post/2011/02/16/hello
      r.on "post/:y/:m/:d/:slug" do |y, m, d, slug|
        "#{y}-#{m}-#{d} #{slug}" #=> "2011-02-16 hello"
      end

      # /username/foobar
      r.on "username/:username" do |username|
        user = User.find_by_username(username) # username == "foobar"

        # /username/foobar/posts
        r.on "posts" do

          # You can access `user` here, because the `on` blocks
          # are closures.
          "Total Posts: #{user.posts.size}" #=> "Total Posts: 6"
        end

        # /username/foobar/following
        r.on "following" do
          user.following.size.to_s #=> "1301"
        end
      end

      # /search?q=barbaz
      r.on "search", :param=>"q" do |query|
        res.write "Searched for #{query}" #=> "Searched for barbaz"
      end
    end

    # only POST requests
    r.post do
      r.on "login" do

        # POST /login, user: foo, pass: baz
        r.on {:param=>"user"}, {:param=>"pass"} do |user, pass|
          "#{user}:#{pass}" #=> "foo:baz"
        end

        # If the params `user` and `pass` are not provided, this
        # will get executed.
        "You need to provide user and pass!"
      end
    end
  end
end
```

Status codes
------------

When it comes time to finalize a response, if a status code has not
been set manually, it will use a 200 status code if anything has been
written to the response, otherwise it will use a 404 status code.
This enables the principle of least surprise to work, where if you
don't handle an action, a 404 response is assumed.

You can always set the status code manually via the status attribute
for the response.

``` ruby
route do |r|
  r.get do
    r.on "hello" do
      r.status = 200
    end
  end
end

Security
--------

The favorite security layer for Sinuba is
[Rack::Protection][rack-protection]. It is not included by default
because there are legitimate uses for plain Sinuba (for instance,
when designing an API).

If you are building a web application, by all means make sure
to include a security layer. As it is the convention for unsafe
operations, only POST, PUT and DELETE requests are monitored.

You should also always set a session secret to some undisclosed
value. Keep in mind that the content in the session cookie is
*not* encrypted.

[rack-protection]: https://github.com/rkh/rack-protection

``` ruby
require "sinuba"
require "rack/protection"

Sinuba.define do
  use Rack::Session::Cookie, :secret => "__a_very_long_string__"
  use Rack::Protection
  use Rack::Protection::RemoteReferrer

  route do |r|
    # Now your app is protected against a wide range of attacks.
    ...
  end
end
```

HTTP Verbs
----------

The main match method is `r.on`, but as displayed above, you can also
use `r.get` or r.post`.  These are just sugar, so both of these are the same:

    r.get "hello"
    r.on r.get?, "hello"

Request and Response
--------------------

While the request object is yielded to the route block, it is also
available via the `request` method.  Likewise, the response object
is available via the `response` method.

The request object is an instance of a subclass of Rack::Request
that uses Sinuba::RequestMethods, and the response object is an
instance of a subclass of Rack::Response that uses Sinuba::ResponseMethods.

If you want to access the `env` hash for the request, it is available
via `r.env`.

If you want to extend the request and response objects with additional
modules, you can do so via plugins.

Pollution
---------

Sinuba tries very hard to avoid polluting the scope in which the
`route` block operates.  The only instance variables defined
by Sinuba are `@\_block`, `@\_request`, and `@\_response`.  The
only methods defined (beyond the default methods for `Object`) are:
`opts`, `request`, `response`, `call`, and `session`.

Captures
--------

You may have noticed that some matchers yield a value to the block. The rules
for determining if a matcher will yield a value are simple:

1. Regex captures: `"posts/(\\d+)-(.*)"` will yield two values, corresponding to each capture.
2. Placeholders: `"users/:id"` will yield the value in the position of :id.
3. Symbols: `:foobar` will yield if a segment is available.
4. File extensions: `:extension=>"css"` will yield the basename of the matched file.
5. Parameters: `:param=>"user"` will yield the value of the parameter user, if present.

The first case is important because it shows the underlying effect of regex
captures.

In the second case, the substring `:id` gets replaced by `([^\\/]+)` and the
string becomes `"users/([^\\/]+)"` before performing the match, thus it reverts
to the first form we saw.

In the third case, the symbol, no matter what it says, gets replaced
by `"([^\\/]+)"`, and again we are in presence of case 1.

The fourth case, again, reverts to the basic matcher: it generates the string
`"([^\\/]+?)\.#{ext}\\z"` before performing the match.

The fifth case is different: it checks if the the parameter supplied is present
in the request (via POST or QUERY_STRING) and it pushes the value as a capture.

Composition
-----------

You can mount a Sinuba app, along with middlewares, inside another Sinuba app,
via `r.run`:

``` ruby
API = Sinuba.define do
  use SomeMiddleware

  route do |r|
    r.on :param=>'url' do |url|
      ...
    end
  end
end

run(Sinuba.define do
  route do |r|
    r.on "api" do
      r.run API
    end
  end
end.app)
```

Testing
-------

Given that Sinuba is essentially Rack, it is very easy to test with
`Rack::Test` or `Capybara`. Sinuba's own tests are written
with a combination of rspec and [Rack::Test][rack-test].  The
default rake task will run the specs for Sinuba, if rspec is installed.

Settings
--------

Each Sinuba app can store settings in the `opts` hash. The settings are
inherited if you happen to subclass `Sinuba`.  

``` ruby
Sinuba.settings[:layout] = "guest"

class Users < Sinuba; end
class Admin < Sinuba; end

Admin.settings[:layout] = "admin"

assert_equal "guest", Users.settings[:layout]
assert_equal "admin", Admin.settings[:layout]
```

Feel free to store whatever you find convenient.  Note that when subclassing,
Sinuba only does a shallow clone.  If you store nested structures and plan
to mutate them in subclasses, it is your responsibility to dup the nested
structures as well.  The plugins that ship with Sinuba all handle this.

Rendering
---------

Sinuba ships with a plugin that provides helpers for rendering templates. It uses
[Tilt][tilt], a gem that interfaces with many template engines. The erb engine is
used by default.

Note that in order to use this plugin you need to have [Tilt][tilt] installed, along
with the templating engines you want to use.

This plugin adds the `render` and `view` methods, for rendering templates.
The difference between `render` and `view` is that `view` will by default
attempt to render the template inside the default layout template, where
`render` will just render the template.

``` ruby
Sinuba.define do
  plugin :render

  route do |r|
    @var = '1'

    r.on "render" do
      # Renders the views/home.erb template, which will have access to the
      # instance variable @var, as well as local variable content
      render("home", :locals=>{:content => "hello, world"})
    end

    r.on "render" do
      @var2 = '1'

      # Renders the views/home.erb template, which will have access to the
      # instance variables @var and @var2, and takes the output of that and
      # renders it inside views/layout.erb (which should yield where the
      # content should be inserted).
      view("home")
    end
  end
end
```

You can override the default rendering options by passing a hash to the plugin,
or modifying the `render_opts` hash after loading the plugin:

``` ruby
Sinuba.define do
  plugin :render, :engine=>'slim' # Tilt engine/template file extension to use
  render_opts[:views] = 'admin_views' # Default views directory
  render_opts[:layout] = "admin_layout" # Default layout template
  render_opts[:layout_opts] = {:engine=>'haml'} # Default layout template options
  render_opts[:opts] = {:default_encoding=>'UTF-8'} # Default template options
end
```

Plugins
-------

Sinuba provides a way to extend its functionality with plugins.  Plugins can
override any Sinuba method and call `super` to get the default behavior.

### Included Plugins

* not\_found: Adds a `not_found` block that is called for all 404 responses
  without bodies.
* render: Adds support for rendering templates via tilt, as described above.

### How to create plugins

Authoring your own plugins is pretty straightforward.  Plugins are just modules
that contain one of the following modules:

* InstanceMethods: module included in the Sinuba class
* ClassMethods: module that extends the Sinuba class
* RequestMethods: module included in the class of the request
* ResponseMethods: module included in the class of the response

So a simple plugin to add an instance method would be:

``` ruby
module MyOwnHelper
  module InstanceMethods
    def markdown(str)
      BlueCloth.new(str).to_html
    end
  end
end

Sinuba.plugin MyOwnHelper
```

A more complicated plugin can make use of `Sinuba.opts` to provide default
values. In the following example, note that if the module has a `configure` method, it will
be called as soon as it is included, along with the opts given to the plugin method

``` ruby
module Render
  def self.configure(app, opts={})
    app.settings[:engine] = opts[:engine] || "erb"
  end

  module InstanceMethods
    def render(template, opts={})
      ...
    end
  end
end

Sinuba.plugin Render, :engine=>'slim'
```

License
-------

MIT

Maintainer
----------

Jeremy Evans <code@jeremyevans.net>
