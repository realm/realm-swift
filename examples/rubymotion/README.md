# RubyMotion Examples

***RubyMotion support is in the experimental phase. We make no claims towards stability and/or performance when using Realm in RubyMotion.***

## RealmRubyMotionSimpleExample

Simple example demonstrating how to use Realm in a [RubyMotion](http://www.rubymotion.com) iOS app. Make sure to have run `sh build.sh ios` from the root of this repo before building and running this example. You can build and run this example by running `rake` from the `RealmRubyMotionSimpleExample` directory.

To use Realm in your own RubyMotion iOS or OSX app, you must define your models in Objective-C and place them in the `models/` directory. Then in your `Rakefile`, define the following `vendor_project`s:

```ruby
app.vendor_project 'path/to/Realm/Realm.framework', :static, :products => ['Realm'], :force_load => false
app.vendor_project 'models', :static, :cflags => '-F /path/to/Realm/'
```
