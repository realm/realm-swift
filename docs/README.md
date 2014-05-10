Realm Documentation
===================

You probably want to go and [read the docs on the Realm project website](http://realm.io/docs/ios)

Most of the documentation for the project is contained inline as comments in our header files. The `docs/source/` folder contains additional long-form articles such as our docs index page.

You can generate the docs locally by using the build.sh script at the root of this repository. This requires installation of [appledoc](https://github.com/tomaz/appledoc/releases/tag/v2.2-963).

```
sh build.sh docs
```

This will generate HTML docs under `docs/html/` and Apple docset packages under `docs/docset`. You can view the docset locally with tools like [Dash](http://kapeli.com/dash) or in Xcode directly with e.g. [Docs for XCode](http://georiot.co/docsforxcode).
