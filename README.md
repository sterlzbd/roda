Roda
====

Roda is a routing tree web framework.

Installation
------------

``` console
$ gem install roda
```

Resources
---------

* Website: http://roda.jeremyevans.net
* Source: http://github.com/jeremyevans/roda
* Bugs: http://github.com/jeremyevans/roda/issues
* Google Group: http://groups.google.com/group/ruby-roda
* IRC: irc://chat.freenode.net/#roda

Usage
-----

Here's a simple application, showing how the routing tree works:

``` ruby
# cat config.ru
require "roda"

class App < Roda
  use Rack::Session::Cookie, :secret => "__a_very_long_string__"

  route do |r|
    # matches any GET request
    r.get do

      # matches GET /
      r.is "" do
        r.redirect "/hello"
      end

      # matches GET /hello or GET /hello/.*
      r.on "hello" do

        # matches GET /hello/world
        r.is "world" do
          "Hello world!"
        end

        # matches GET /hello
        r.is do
          "Hello!"
        end
      end
    end
  end
end

run App.app
```

You can now run `rackup` and enjoy what you have just created.

Here's a breakdown of what is going on in the above block:

After requiring the library and subclassing Roda, the `use` method
is called, which loads a rack middleware into the current
application.

The `route` block is called whenever a new request comes in, 
and it is yieled an instance of a subclass of `Rack::Request`
with some additional methods for matching routes.  By
convention, this argument should be named `r`.

The primary way routes are matched in Roda is by calling
`r.on`, or a method like `r.get` or `r.is` which calls `r.on`.
`r.on` takes each of the arguments given and tries to match them to
the current request.  If it is able to successfully match
all of the arguments, it yields to the `r.on` block, otherwise
it returns immediately.

`r.get` is a shortcut that matches any GET request, and
`r.is` is a shortcut that ensures the the exact route is
matched and there are no further entries in the path.

If `r.on` matches and control is yielded to the block, whenever
the block returns, the response will be returned.  If the block
returns a string and the response body hasn't already been
written to, the block return value will interpreted as the body
for the response.  If none of the `r.on` blocks match and the
route block returns a string, it will be interpreted as the body
for the response.

`r.redirect` immediately returns the response, allowing for
code such as `r.redirect(path) if some_condition`.

The `.app` at the end is an optimization, which you can leave
off, but which saves a few methods call for every response.

Matchers
--------

Here's an example showcasing how different matchers work:

``` ruby
class App < Roda
  use Rack::Session::Cookie, :secret => "__a_very_long_string__"

  route do |r|
    # only GET requests
    r.get do

      # /
      r.is "" do
        "Home"
      end

      # /about
      r.is "about" do
        "About"
      end

      # /styles/basic.css
      r.is "styles", :extension => "css" do |file|
        "Filename: #{file}" #=> "Filename: basic"
      end

      # /post/2011/02/16/hello
      r.is "post/:y/:m/:d/:slug" do |y, m, d, slug|
        "#{y}-#{m}-#{d} #{slug}" #=> "2011-02-16 hello"
      end

      # /username/foobar
      r.on "username/:username" do |username|
        user = User.find_by_username(username) # username == "foobar"

        # /username/foobar/posts
        r.is "posts" do

          # You can access `user` here, because the `on` blocks
          # are closures.
          "Total Posts: #{user.posts.size}" #=> "Total Posts: 6"
        end

        # /username/foobar/following
        r.is "following" do
          user.following.size.to_s #=> "1301"
        end
      end

      # /search?q=barbaz
      r.is "search", :param=>"q" do |query|
        "Searched for #{query}" #=> "Searched for barbaz"
      end
    end

    # only POST requests
    r.post do
      r.is "login" do

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

Here's a description of the matchers.  Note that segment as used
here means one part of the path preceeded by a /.  So a path such
as `/foo/bar//baz` has 4 segments, `/foo`, `/bar`, `/` and `/baz`.
The `/` here is considered the empty segment.

### String

If it does not contain a colon or slash, it matches single segment
with the text of the string, preceeded by a slash.

  "" matches "/"
  "foo" matches "/foo"
  "foo" does not match "/food"

If it contains any slashes, it matches one additional segment for
each slash:

  "foo/bar" matches "/foo/bar"
  "foo/bar" does not match "/foo/bard"

If it contains a colon followed by any \w characters, the colon and
remaing \w characters matches any nonempty segment that contains at
least one character:

  "foo/:id" matches "/foo/bar", "/foo/baz", etc.
  "foo/:id" does not match "/fo/bar"

You can use multiple colons in a string:

  ":x/:y" matches "/foo/bar", "/bar/foo" etc.
  ":x/:y" does not match "/foo", "/bar/"

You can prefix colons:

  "foo:x/bar:y" matches "/food/bard", "/fool/bart", etc.
  "foo:x/bar:y" does not match "/foo/bart", "/fool/bar", etc.

If any colons are used, the block will yield one argument for
each segment matched containing the matched text.  So:

  "foo:x/:y" matching "/fool/bar" yields "l", "bar"

Colons that are not followed by a \w character are matched literally:

  ":/a" matches "/:/a"

Note that strings are regexp escaped before being used in a regular
expression, so:

  "\\d+(/\\w+)?" matches "\d+(/\w+)?"
  "\\d+/\\w+" does not match "123/abc"

### Regexp

Regexps match one or more segments by looking pattern preceeded by a
slash:

  /foo\w+/ matches "/foobar"
  /foo\w+/ does not match "/foo/bar"

If any patterns are captured by the regexp, they are yielded:

  /foo\w+/ matches "/foobar", yields nothing
  /foo(\w+)/ matches "/foobar", yields "bar" 

### Symbol

Symbols match any segment with one or more characters,
yielding the segment:

  :id matches "/foo" yields "foo"
  :id does not match "/"

### Proc

Procs match unless they return false or nil:

  proc{true} matches anything
  proc{false} does not match anything

Procs don't capture anything by default, but they can if you add
them to `r.captures`.

### Arrays

Arrays match when any of their elements matches.  If multiple matchers
are given to `r.on`, they all must match (an AND condition), while
if an array of matchers is given, only one needs to match (an OR
condition).  Evaluation stops at the first matcher that matches.

Additionally, if the matched object is a String, the string is yielded.
This makes it easy to handle multiple strings without a Regexp:

  %w'page1 page2' matches "/page1", "/page2"
  [] does not match anything

### Hash

Hashes call a registered matcher with the given key using the hash value,
and match if that matcher returns true.  Keys should always be symbols.

The default registered matchers included with Roda are documented below.
You can add your own hash matchers by adding the appropriate match\_\*
method to the request class using the request\_module method:

  class App < Roda
    request_module do
      def match_foo(v)
        ...
      end
    end

    route do |r|
      r.on :foo=>'bar' do
        ...
      end
    end
  end


#### :extension

The :extension matcher matches any nonempty path ending with the given extension:

  :extension => "css" matches "/foo.css", "/bar.css"
  :extension => "css" does not match "/foo.css/x", "/foo.bar", "/.css"

This matcher yields the part before the extension.  Note that unlike other
matchers, this matcher assumes terminal behavior, it doesn't match if there
are additional segments.

#### :method

This matches the method of the request.  You can provide an array to specify multiple
request methods and match on any of them:

  :method => :post matches POST
  :method => %w'post patch' matches POST and PATCH

#### :param

The :param matcher matches if the given parameter is present, even if empty.

  :param => "user" matches "/foo?user=bar", "/foo?user="
  :param => "user" does not matches "/foo"

#### :param!

The :param! matcher matches if the given parameter is present and not empty.

  :param! => "user" matches "/foo?user=bar"
  :param! => "user" does not matches "/foo", "/foo?user="

#### :term

The :term matcher matches if true and there are no segments left.  This matcher is
added by `r.is` to ensure an exact path match.

  :term => true matches ""
  :term => true does not match "/"
  :term => false matches "/"
  :term => false does not match ""

### false, nil

If false or nil is given directly as a matcher, it doesn't match anything.

### Everything else

Everything else matches anything.

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
    r.is "hello" do
      r.status = 200
    end
  end
end

Security
--------

The favorite security layer for Roda is
[Rack::Protection][rack-protection]. It is not included by default
because there are legitimate uses for plain Roda (for instance,
when designing an API).

If you are building a web application, by all means make sure
to include a security layer. As it is the convention for unsafe
operations, only POST, PUT and DELETE requests are monitored.

You should also always set a session secret to some undisclosed
value. Keep in mind that the content in the session cookie is
*not* encrypted.

[rack-protection]: https://github.com/rkh/rack-protection

``` ruby
require "roda"
require "rack/protection"

class App < Roda
  use Rack::Session::Cookie, :secret => "__a_very_long_string__"
  use Rack::Protection
  use Rack::Protection::RemoteReferrer

  route do |r|
    # Now your app is protected against a wide range of attacks.
    ...
  end
end
```

Verb Methods
------------

The main match method is `r.on`, but as displayed above, you can also
use `r.get` or r.post`.  When called without any arguments, these
call `r.on` as long as the request has the appropriate method, so:

    r.get{}

is syntax sugar for:

    r.on{} if r.get? 

If any arguments are given to the method, these call `r.is` as long as
the request has the appropriate method, so:

    r.post(""){}

is syntax sugar for:

    r.is(""){} if r.post?


Request and Response
--------------------

While the request object is yielded to the route block, it is also
available via the `request` method.  Likewise, the response object
is available via the `response` method.

The request object is an instance of a subclass of Rack::Request
with some additional methods, and the response object is an
instance of a subclass of Rack::Response with some additional
methods.

If you want to extend the request and response objects with additional
modules, you can do so via the request\_module or response\_module
methods, or via plugins.

Pollution
---------

Roda tries very hard to avoid polluting the scope in which the
`route` block operates.  The only instance variable defined by base
Roda is `@\_request`.  The only methods defined (beyond the default
methods for `Object`) are: `env`, `opts`, `request`, `response`, `call`, 
`session`, and `\_route` (private). Constants inside the Roda namespace
are all prefixed with Roda.

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

You can mount a Roda app, along with middlewares, inside another Roda app,
via `r.run`:

``` ruby
class API < Roda
  use SomeMiddleware

  route do |r|
    r.is do
      ...
    end
  end
end

Roda.route do |r|
  r.on "api" do
    r.run API
  end
end

run Roda.app
```

Testing
-------

It is very easy to test Roda with `Rack::Test` or `Capybara`. Roda's
own tests are written with a combination of rspec and [Rack::Test][rack-test].
The default rake task will run the specs for Roda, if rspec is installed.

Settings
--------

Each Roda app can store settings in the `opts` hash. The settings are
inherited if you happen to subclass `Roda`.  

``` ruby
Roda.opts[:layout] = "guest"

class Users < Roda; end
class Admin < Roda; end

Admin.opts[:layout] = "admin"

assert_equal "guest", Users.opts[:layout]
assert_equal "admin", Admin.opts[:layout]
```

Feel free to store whatever you find convenient.  Note that when subclassing,
Roda only does a shallow clone.  If you store nested structures and plan
to mutate them in subclasses, it is your responsibility to dup the nested
structures inside Roda.inherited as well.  The plugins that ship with
Roda all handle this.  Also, note that this means that future modifications
to the parent class after subclassing do not affect the subclass.

Rendering
---------

Roda ships with a plugin that provides helpers for rendering templates. It uses
[Tilt][tilt], a gem that interfaces with many template engines. The erb engine is
used by default.

Note that in order to use this plugin you need to have [Tilt][tilt] installed, along
with the templating engines you want to use.

This plugin adds the `render` and `view` methods, for rendering templates.
The difference between `render` and `view` is that `view` will by default
attempt to render the template inside the default layout template, where
`render` will just render the template.

``` ruby
class App < Roda
  plugin :render

  route do |r|
    @var = '1'

    r.is "render" do
      # Renders the views/home.erb template, which will have access to the
      # instance variable @var, as well as local variable content
      render("home", :locals=>{:content => "hello, world"})
    end

    r.is "view" do
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
class App < Roda
  plugin :render, :engine=>'slim' # Tilt engine/template file extension to use
  render_opts[:views] = 'admin_views' # Default views directory
  render_opts[:layout] = "admin_layout" # Default layout template
  render_opts[:layout_opts] = {:engine=>'haml'} # Default layout template options
  render_opts[:opts] = {:default_encoding=>'UTF-8'} # Default template options
end
```

Plugins
-------

Roda provides a way to extend its functionality with plugins.  Plugins can
override any Roda method and call `super` to get the default behavior.

### Included Plugins

These plugins ship with roda:

* all\_verbs: Adds routing methods to the request for all http verbs.
* default\_headers: Override the default response headers used.
* error\_handler: Adds a `error` block that is called for all responses that
  raise exceptions.
* flash: Adds a flash handler, requires sinatra-flash.
* h: Adds h method for html escaping.
* halt: Augments request#halt method to take status and/or body or status,
  headers, and body.
* header\_matchers: Adds host, header, and accept hash matchers.
* hooks: Adds before and after methods to run code before and after requests.
* indifferent\_params: Adds params method with indifferent access to params,
  allowing use of symbol keys for accessing params.
* middleware: Allows the Roda app to be used as a rack middleware, calling the
  next middleware if no route matches.
* multi\_route: Adds the ability for multiple named route blocks, with the
  ability to dispatch to them add any point in the main route block.
* not\_found: Adds a `not_found` block that is called for all 404 responses
  without bodies.
* pass: Adds a pass method allowing you to skip the current `r.on` block as if
  it did not match.
* render: Adds support for rendering templates via tilt, as described above.
* streaming: Adds support for streaming responses.

### External Plugins

The following libraries include Roda plugins:

* forme: Adds support for easy HTML form creation in erb templates.
* autoforme: Adds support for easily creating a simple administrative front
  end for Sequel models.

### How to create plugins

Authoring your own plugins is pretty straightforward.  Plugins are just modules
that contain one of the following modules:

* InstanceMethods: module included in the Roda class
* ClassMethods: module that extends the Roda class
* RequestMethods: module included in the class of the request
* ResponseMethods: module included in the class of the response

If the plugin responds to load\_dependencies, it will be called first, and should
be used if the plugin depends on another plugin.

If the plugin responds to configure, it will be called last, and should be
used to configure the plugin.

Both load\_dependencies and configure are called with the additional arguments
and block given to the plugin call.

So a simple plugin to add an instance method would be:

``` ruby
module MarkdownHelper
  module InstanceMethods
    def markdown(str)
      BlueCloth.new(str).to_html
    end
  end
end

Roda.plugin MarkdownHelper
```

### Registering plugins

If you want to ship a Roda plugin in a gem, but still have
Roda load it automatically via `Roda.plugin :plugin_name`, you should
place it where it can be required via `roda/plugins/plugin_name`, and
then have the file register it as a plugin via `Roda.register_plugin`.
It's recommended but not required that you store your plugin module
in the Roda::RodaPlugins namespace:

``` ruby
module Roda
  module RodaPlugins
    module Markdown
      module InstanceMethods
        def markdown(str)
          BlueCloth.new(str).to_html
        end
      end
    end
  end

  register_plugin :markdown, RodaPlugins::Markdown
end
```

You should avoid creating your module directly in the `Roda` namespace
to avoid polluting the namespace.

Inspiration
-----------

Roda was inspired by Cuba and Sinatra, two other Ruby web frameworks.
It started out as a fork of Cuba, from which it borrows the idea of using
a routing tree.  From Sinatra it takes the ideas that route blocks
should return the request bodies and that routes should be canonical.
It pilfers the idea for an extensible plugin system from the
Ruby database library Sequel.

License
-------

MIT

Maintainer
----------

Jeremy Evans <code@jeremyevans.net>
