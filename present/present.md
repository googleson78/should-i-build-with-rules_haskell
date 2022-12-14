---
title: Should I rules_haskell?
theme: beige
revealOptions:
  transition: none
  progress: false
  controlsBackArrows: visible
  controlsTutorial: false
---

<style>
  .reveal .gazelle {
    display:block;
    margin-top:auto;
    margin-bot:auto;
    margin-left:auto;
    margin-right:auto;
    height:50%;
    width: 50%;
  }

  .reveal .slide-background-content {
    background-image: url(./T_Mark.svg);
    height: 50px;
    width: 50px;
    position: absolute;
    top: 20px;
    right: 35px;
  }
</style>

---

## Should I Build My Project with `rules_haskell`?

---

### `whoamai`

* Georgi Lyubenov (he/him)

* `godzbanebane@gmail.com`

* https://github.com/googleson78

* matrix `@googleson78:tryp.io`

* @Tweag

Note:
~One year of bazel at Tweag

~4-5 Haskell experience

love to teach Haskell and Agda

---

What is `rules_haskell`?
<p class="fragment" data-fragment-index="0">A Bazel extension for building Haskell</p>

Notes:
"let's first talk about bazel"

---

## Bazel 101

----

_**Build tool**_ that started out internally at Google

Therefore it has the following considerations:
* many languages <!-- .element: class="fragment" data-fragment-index="0" -->
* a huge monorepo <!-- .element: class="fragment" data-fragment-index="1" -->
* slow builds <!-- .element: class="fragment" data-fragment-index="2" -->
* dev envs are unified  <!-- .element: class="fragment" data-fragment-index="3" -->

Note:

many languages - must be extensible, many extensions exist

huge monorepo - lazy evaluation of builds

very slow builds - caching and RBE

managing system deps is not such a focus

----

Bazel tries to be _**abstract**_

<ul>
  <li class="fragment" data-fragment-index="0">Not tied to any one language's build system:
    <ul>
    <li class="fragment" data-fragment-index="1">dependencies (inputs)</li>
    <li class="fragment" data-fragment-index="2">actions</li>
    <li class="fragment" data-fragment-index="3">artifacts (outputs)</li>
    </ul>
  </li>
  <li class="fragment" data-fragment-index="4">We can write Bazel extensions - <em>rulesets</em> - to add support for different languages.</li>
</ul>

<p class="fragment" data-fragment-index="5"> Bazel is a <em><b>polyglot</b></em> build system.

Note:

not tied - core concepts:
* dependencies (inputs)
* actions (compilation, linking)
* outputs

rulesets - rules_haskell

----

Bazel tries to be _**declarative**_

<ul>
  <li class="fragment" data-fragment-index="1">Instead of listing statements to execute, we build a dependency graph by using <em>rules</em> that define <em>targets</em>:

  ```starlark
  haskell_library(
    name = "lib",
    srcs = [ "src/Lib.hs" ],
  )
  haskell_binary(
    name = "bin",
    srcs [ "app/Main.hs" ],
    deps = [ ":lib" ],
  )
  ```
  <!-- .element: class="fragment" data-fragment-index="2" -->
  ```
  bin -> lib
  ```
  <!-- .element: class="fragment" data-fragment-index="3" -->

  </li>
  <li class="fragment" data-fragment-index="4">All dependencies must be statically declared.*
  </li>
</ul>

Note:
No manually specified order of execution

rule:
specifies how to go from input to output

inputs may be other targets

target:
* file
* "things" defined by other rules
* misc stuff

\* - builtin rules can be dynamic

----

Bazel is _**artifact based**_
<ul>
  <li class="fragment" data-fragment-index="0">The main requests you make to Bazel are "please generate this artifact".</li>
  <li class="fragment" data-fragment-index="1">Bazel will figure out the <b><em>exact</em></b> set of actions to run to produce your artifact.</li>
  <li class="fragment" data-fragment-index="2">This is done by referencing <em>labels</em>

  ```python
  # contents of /path/to/package/BUILD.bazel
  haskell_library(
    name = "lib",
    srcs = [ "src/Lib.hs" ],
  )
  ```

  ```sh
  > bazel build //path/to/package:lib
  ```
  </li>
</ul>

Note:
Effectively requesting nodes in our graph

exact - no more and no less

What is a label?
name of a target = package + name in rule

What is a package?
directory with BUILD.bazel file in it

----

Packages are organised in a _workspace_.

```
//
????????? WORKSPACE.bazel
???
????????? path
 ???? ????????? to
 ????     ????????? package
 ????     ??????? ????????? BUILD.bazel
 ????     ????????? another-package
 ????         ????????? BUILD.bazel
```

<p class="fragment" data-fragment-index="0"> <code>WORKSPACE</code> contains <em>repository rules</em> to pull in external deps, e.g. system libs, compilers, etc.</p>

Note:
Workspace == folder with WORKSPACE in it

// refers to root

Workspace pulls in external dependencies, such as rules_haskell

packages in a single workspace can reference each other

----

Bazel builds aim to be _**reproducible and hermetic**_

<ul>
  <li class="fragment" data-fragment-index="0">Build actions are sandboxed by default</li>
  <li class="fragment" data-fragment-index="1">We can capture runtime dependencies for executable/test targets as well.</li>
  <li class="fragment" data-fragment-index="2">Bazel has support for injecting tools, e.g. compilers, coreutils, etc.</li>
</ul>

<p class="fragment" data-fragment-index="3">
Capturing everything required for a build allows us to model builds as pure functions:
</p>
<p class="fragment" data-fragment-index="4">
Same inputs -> same output
</p>
<p class="fragment" data-fragment-index="5">
Enables remote caching and remote builds
</p>

Note:
Sandboxes - can only access declared inputs

Note that the system is **not** sandboxed - we can refer (absolute path) to /usr/bin/whatever

runtime dependencies get put inside sandbox when tests run

injecting tools - can provide specific ghc/gcc/etc for the rule to run

everything required:
* tools
* compile time dependencies (sources)
* runtime deps (data files)

---

## `rules_haskell` 101

by Tweag <!-- .element: class="fragment" data-fragment-index="0" -->

[haskell.build](https://haskell.build/)  <!-- .element: class="fragment" data-fragment-index="0" -->

Note:
disclosure: by Tweag

----
Rules:

`haskell_{library,binary,test,doc,repl}`

Define targets to build a {library,binary,test,haddocks,repl}. <!-- .element: class="fragment" data-fragment-index="0" -->

----

```starlark
haskell_library(
  name = "lib",
  srcs = [ "src/Foo.hs", "src/Bar.hs" ],
)
haskell_binary(
  name = "bin",
  srcs [ "app/Main.hs" ],
  deps = [ ":lib" ],
  data = [ "asset.txt" ],
)
haskell_test(
  name = "test",
  srcs [ "app/Main.hs" ],
  deps = [ ":lib" ],
  data = [ "//mock:produce-mock-results" ]
)
```

Note:
we've grouped `Foo` and `Bar` - by default bazel looks at targets as atomic unit, hence

caching+parallelism will only happen at that level

changing `Foo` => rebuild the whole of `lib`, including `Bar`

data can be concrete file or another target, meaning the outputs from that target

----

`rules_haskell` has repository rules for making `ghc` available to Bazel.

Notes:

Repository rules = define things for the entire workspace

----

There are a few different ways to get yourself a `ghc`:
<ul>
  <li class="fragment" data-fragment-index="0">via nix, usually used with <code>rules_nixpkgs</code></li>
  <li class="fragment" data-fragment-index="1">via a distribution tarball ala <code>stack</code></li>
  <li class="fragment" data-fragment-index="2">manually register a local <code>ghc</code> distribution</li>
</ul>

----

`rules_haskell` also has a rule to pull in the packages in a stackage snapshot as dependencies.

We can specify an LTS or use `stack`'s custom snapshot format and all the features it provides.

Note:
so adding hackage deps, git deps, etc

these dependencies are built with cabal for compatibility Setup.hs

----
```starlark
stack_snapshot(
    name = "stackage",
    packages = ["text", "vector"],
    snapshot = "lts-18.18",
)
```

----

`haskell_module`

A rule that allows us to be more granular. <!-- .element: class="fragment" data-fragment-index="0" -->

Instead of grouping whole packages into targets, we group individual modules into targets. <!-- .element: class="fragment" data-fragment-index="1" -->

Cross-package module dependencies <!-- .element: class="fragment" data-fragment-index="2" -->.

Note:
bazel can only rebuild individual modules.

cross-package module deps: not present in other build tools faik

----

```starlark
haskell_library(
  name = "lib",
  mods = [ ":ModFoo", ":ModBar" ]
)
haskell_module(
  name = "ModFoo",
  src = "src/Foo.hs",
)
haskell_module(
  name = "ModBar",
  src = "src/Bar.hs",
  deps = [ ":ModFoo" ],
)
```

Note:

boilerplate - duplicating all the imports

----

`gazelle`

![gazelle](./gazelle.jpg) <!-- .element class="gazelle" -->

----

`gazelle`

Generates `BUILD.bazel` files from existing (usually) manifest files (e.g. `.cabal`).

Use cases: <!-- .element: class="fragment" data-fragment-index="0" -->
* support both build systems simultaneously <!-- .element: class="fragment" data-fragment-index="1" -->
* gradually migrate to Bazel <!-- .element: class="fragment" data-fragment-index="2" -->

Note:

originally for golang, supports extensions

both build systems: useful for tooling

----

`gazelle_cabal`

`gazelle` extension; allows `BUILD.bazel` files to be generated from `.cabal` files.

<p class="fragment" data-fragment-index="0"> Also updates <code>stack_snapshot</code></p>

Note:

updates stack_snapshot with packages found in .cabal

works quite nicely to get you 90% of the way there, but not everything e.g. Setup.hs cabal Paths_

----

`gazelle_haskell_modules`

`gazelle` extension; automates the generation of `haskell_module` targets from existing `haskell_{library,binary,etc}` targets.

Note:

needs to scan hs files for imports to determine deps

makes haskell_module usage viable

can also autodetect hs files

---

## yeas

----

## parallelism gains?

Module level granularity allows module level parallelism <!-- .element: class="fragment" data-fragment-index="0" -->

["Incremental Builds For Haskell With Bazel"](https://www.tweag.io/blog/2022-06-23-haskell-module/)\* <!-- .element: class="fragment" data-fragment-index="1" -->

Cross-package dependencies also help here <!-- .element: class="fragment" data-fragment-index="2" -->

<p class="fragment" data-fragment-index="3">The <a href=https://github.com/ghc-proposals/ghc-proposals/pull/540>jsem proposal</a> could even things out</p>

<sub class="fragment" data-fragment-index="1"><sup>\* currently not realised because persistent worker is not merged yet</sub></sup>

Note:
not found in cabal or stack by default, jsem explains issues

evidence: Facundo haskell_module on cabal builds faster than with cabal

cross-package: start builds faster, parallelise more

jsem proposal more fine grained control over ghc workers, perhaps catchup

----

## Polyglot

We often generate things from Haskell and vice versa <!-- .element: class="fragment" data-fragment-index="0" -->

Having dependencies cross language is awesome <!-- .element: class="fragment" data-fragment-index="1" -->

Covers all sorts of generations, e.g. Elm types from Haskell definitions <!-- .element: class="fragment" data-fragment-index="2" -->

["Converting a Polyglot Project Build to Bazel"](https://www.tweag.io/blog/2022-10-20-bazel-example-servant-elm-1/) <!-- .element: class="fragment" data-fragment-index="2" -->

Note:
annoying:
* we end up writing additional tooling/scripts or remembering to run things manually
* deps are not so precise, sometimes we can avoid recompiling when it's not actually needed,
* end up with dependency management system anyway

awesome cross language: we can skip tests!

----

## Remote caching

Built into Bazel <!-- .element: class="fragment" data-fragment-index="0" -->

Solves caching for CI <!-- .element: class="fragment" data-fragment-index="1" -->

Solves switching branches <!-- .element: class="fragment" data-fragment-index="2" -->

Requires some hermeticity efforts <!-- .element: class="fragment" data-fragment-index="3" -->

<p class="fragment" data-fragment-index="4"><code>cabal</code>: some <a href=https://github.com/haskell/cabal/issues/5582>discussions</a> and some <a href=https://github.com/haskell-works/cabal-cache>tooling</a> exist, not widely used</p>

<p class="fragment" data-fragment-index="5"><code>stack</code>: none?</p>

Note:

focus for most of our clients

cache successful test runs

remote cache or local cache

switching branches, checking out prs

cabal discussion: no outcome

cabal-cache: not very popular?

----

## Remote build execution

Built into Bazel <!-- .element: class="fragment" data-fragment-index="0" -->

Alleviate developer machine stress and requirements <!-- .element: class="fragment" data-fragment-index="1" -->

Speedup builds by offloading to beefy machines <!-- .element: class="fragment" data-fragment-index="2" -->

Again, hermeticity requirements <!-- .element: class="fragment" data-fragment-index="3" -->

cabal and stack have no support? <!-- .element: class="fragment" data-fragment-index="4" -->

Note:

---

## nays

----

## HLS

Support is finicky, but possible to get working <!-- .element: class="fragment" data-fragment-index="0" -->

There's some discussion occasionally, improvement does not seem to be impossible <!-- .element: class="fragment" data-fragment-index="1" -->

----

## Incrementality

<p class="fragment" data-fragment-index="0">Using <code>ghc</code> to compile oneshot => can't use <code>ghc</code>'s recompilation checker</p>

<p class="fragment" data-fragment-index="1"><code>rules_haskell</code>: ABI hash change => recompilation</p>

Actual: Recompilation => ABI hash change <!-- .element: class="fragment" data-fragment-index="2" -->

Avoids ~80% of cases <!-- .element: class="fragment" data-fragment-index="3" -->

["Recompilation Avoidance in rules_haskell"](https://www.tweag.io/blog/2022-11-03-blog_recompilation/) <!-- .element: class="fragment" data-fragment-index="4" -->

Note:
oneshot - compile only one file

abi hash: determined by exposed implementation - export list + decl impls

abi hash not sufficient

blogpost describing improvements by Guillaume Genestier

----

## Effort

Yet another language - Starlark <!-- .element: class="fragment" data-fragment-index="0" -->

Requires a lot of domain specific knowledge <!-- .element: class="fragment" data-fragment-index="1" -->

Many solutions possible, but some are betters than others <!-- .element: class="fragment" data-fragment-index="2" -->

Docs are massive <!-- .element: class="fragment" data-fragment-index="3" -->

Need to write rules eventually <!-- .element: class="fragment" data-fragment-index="4" -->

Note:
the language is python though, so np

you need a bazel guy

no existing specific rules write your own hence need internal knowledge

----

## Hiring

Yet another rare complex esoteric thing

Note:
Haskell steep learning curve and esoteric
Bazel steep learning curve and esoteric

---

## Checklist

* do you have a huge code base which is already a monorepo or you are willing to convert to a monorepo? <!-- .element: class="fragment" data-fragment-index="0" -->
* do you require caches to allow for comfortable switching between branches and fast CI? <!-- .element: class="fragment" data-fragment-index="1" -->
* do you want to have developers build on remote machines? <!-- .element: class="fragment" data-fragment-index="2" -->
* are you extensively using more than just Haskell? <!-- .element: class="fragment" data-fragment-index="3" -->

Are the above crucial?

---

----

## nix?

offers *almost* all of the things we've discussed

currently evaluation appears to be too slow

(maintained) module level compilation and recompilation avoidance tooling doesn't exist, and might not soon, because of evaluation slowness

e.g. haskell.nix currently doesn't aim to support incrementality - https://github.com/input-output-hk/haskell.nix/issues/866

---

## thanks :)
