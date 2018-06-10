# Sho: post-framework view library

[![Gem Version](https://badge.fury.io/rb/sho.svg)](http://badge.fury.io/rb/sho)
[![Build Status](https://travis-ci.org/zverok/sho.svg?branch=master)](https://travis-ci.org/zverok/sho)

**Sho** is an experimental **post-framework** Ruby view library. It is based on Tilt and meant to provide entire view layer for a web application (based on any framework or completely frameworkless).

<small>"Sho?" ("Шо?") is a Kharkiv dialecticism, meaning "What?", typically in a slightly aggressive manner. It is chosen as a library name because it is close to "show" in a written and spoken form (and also because "What?" is expected typical reaction to the library).</small>

**Post-framework** means Sho behaves as a decent _library_, neither implying nor forcing _any_ kind of conventions for your code layout and structure.

Currently, if you want your app architecture not to follow strict framework's _frame_, you can take ROM or Sequel for _data layer_; Sinatra, Roda, or Grape for _routing layer_; but for _view layer_, the situation seems to be different. Typical "views" part of the application (say, with Rails, Hanami, Padrino) is bound to a lot of conventions (like "it will look for the corresponding template in that folders") and global configuration, and tightly coupled with routes/controllers ("if you want data from controller to be passed to view, you mark it so an so").

**Sho** is an experiment to provide view layer that is "just Ruby" (= follows the regular intuitions of _Ruby_ programmer, not introducing some hidden conventions that are not deductible from the code) and reuses regular Ruby concepts for code sharing, parameters passing and flow structuring instead of introducing its own concepts like "helpers", "exposures", "locals" (completely unlike local variables!) and so on.

## Basic synopsis

```ruby
# in any class you want
include Sho

sho.template :name, 'path/to/template.erb', :param1, param2: default_value
```

This creates instance method with a signature¹ `YourClass#name(param1:, param2: default_value)`, which, when called, renders the template from `path/to/template.erb`.

<small>¹Due to metaprogramming limitations, real signature of method would be `name(**params)` and check of mandatory params and assignment of defaults is performed by Sho.</small>

You can think about the template as a _method body_, which immediately answers a lot of questions:

* **What context the template is evaluated in?** Like any method: in context of the instance of the class, where the method is defined.
* **What names are available in the template?** The same as in any methods: parameters, and other methods/variables of the instance.
* **How do I do share "helper" code with several templates?** Just in a regular Ruby: extract it to a module, include the module in several classes with views. Or make the base class and inherit from it. Or use any other code sharing technique you are fond of.
* **How do I do "partials" (render one template from another)?** The same as when you want to call one method from another one: just call it.
  ```ruby
  # In `user.rb`
  sho.template :render, 'user.slim'
  # That would be "partial":
  sho.template :status_with_popup, 'user/_status_with_popup.slim'
  ```
  ```slim
  / In `user.slim` (think of it as a body for `User#render` method):
  p
    span.name = name
    / Call of a "partial":
    span.status = status_with_popup
  ```
* **How do I test it? How do I set all the context for testing?** Just as with regular method: just create an instance, and call the method, and test the result.
* **But where do I put this method?** Wherever you wish! Sho does NOT insist on any particular architecture or code layout, which means you can experiment and evaluate several options, like:
  * embed rendering in controller/Sinatra app (or even model, if you want to be really naughty today!) for the very first 30-lines-long prototype, then move it elsewhere (like "Extract Method" refactoring pattern, you know?)
  * embed rendering in your service (operation) objects, so
  * make Users::List class with `#html`, `#atom` and `#json` methods and use it like `Users::List.new(scope).send(request.format)` or `User::List.send(request.format, scope)`
  * make `Trailblazer::Cells`-like one-class-per-template objects to call them like `Users::HtmlList.new(scope).()`
  * ...switch between several of the approaches, or even combine them in the same app!

## Implementation details

**Where should I store the templates?**

Sho doesn't have any global configuration for "templates folder", neither convention for "templates are in `app/views/<current_class_name>`" or something like that. `template` method just looks for templates relative to current working folder (`Dir.pwd`). As it could be tiresome to write `app/views/blah/blah/blah/blah.slim` for each and every method, there is `sho.base_folder = ` class-level setting:

```ruby
# Before
sho.template :profile, 'app/views/users/profile.slim'
sho.template :icon, 'app/views/users/icon.slim'

# After
sho.base_folder = 'app/views/users'
sho.template :profile, 'profile.slim'
sho.template :icon, 'icon.slim'

# If all of your classes and templates are in the same `app/view`, further shortcutting is
# your own responsibility, like:

sho.base_folder = VIEWS_BASE + '/users'
```

Another interesting approach that is made easy by Sho:
```ruby
# In app/view_models/users.rb

# It is like require_relative, template should be stored at
# app/view_models/users/profile.slim
sho.template_relative :profile, 'users/profile.slim'
```

The idea is: as `ViewModels::Users` have `profile.slim` as a `#profile` method body, it is this class' implementation details, so, there is no point to store it in a completely different folder.

**What about layouts?**

**Sho** supports concept of layout with `:_layout` param. It accepts method name, and supposes this method will call `yield` at some point:

```ruby
# in app/view_models/users.rb
sho.template_relative :list, 'users/list.slim', _layout: :main_layout
sho.template :main_layout, 'app/views/main_layout.slim'
```

Sharing of the layout between several classes could be done in the same way as sharing of any other methods: extract it to a common module, and include wherever you like.

**Small-scale usage of the library**

As Sho is a _library_, not a framework, it doesn't require you to switch to Sho-only code immediately and completely. You can try it in some parts of your system, or just in one class. One useful idea is to use it in decorators (like [draper](https://github.com/drapergem/draper)), and Sho provides `inline_template` for this kind of usage:

```ruby
class RatingDecorator < Draper::Decorator
  # ...

  # before:
  def row
    h.content_tag(:tr,
      h.safe_join([
        h.content_tag(:th, "Rated by #{user.name}"),
        h.content_tag(:td, stars),
        h.content_tag(:td, rated_at)
      ]),
      class: 'rating'
    )
  end

  # after:
  include Sho

  sho.inline_template :row,
    slim: <<~SLIM
      tr.rating
        th
          | Rated by
          = user.name
        td = stars
        td = rated_at
    SLIM
end
```

**Template caching**

Sho creates Tilt templates at a moment of the method definition. This seems to lead to most natural behavior: the templates are found and cached at a moment of code loading/reloading (whatever reloader you use).

## Library status

It is fresh and experimental. Tested, documented and stuff, but still not extensively used in production. Nothing guaranteed, but I'll be happy to have at least a meaningful discussion started.

## Author

[Victor Shepelev aka @zverok](https://zverok.github.io)

## License

MIT
