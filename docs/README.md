Realm Documentation
===================

You probably want to go and [read the docs on the Realm project website](http://realm.io/docs/ios/latest/)

You can generate the docs locally by using the build.sh script at the root of this repository. This requires installation of [appledoc](https://github.com/tomaz/appledoc/releases/tag/v2.2-963).

```
sh build.sh docs
```

This will generate docs under `docs/output/` and install the documentation in your Xcode.

You will also find an Apple docset package at the root of that that folder. You can view the docset locally with tools like [Dash](http://kapeli.com/dash) or in Xcode directly with e.g. [Docs for XCode](http://georiot.co/docsforxcode) using the packages generated in `docs/output/` or via the links in the upper right corner of our [online docs](http://realm.io/docs/ios/latest/).
