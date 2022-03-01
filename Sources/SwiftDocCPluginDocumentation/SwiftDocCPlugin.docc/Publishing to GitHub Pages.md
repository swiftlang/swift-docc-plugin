# Publishing to GitHub Pages

Build and publish documentation from your Swift Package to GitHub Pages or other static
web hosts.

## Overview

This documentation is specific to hosting on GitHub Pages but the steps
should apply to most static hosting solutions you're familiar with.

## Configure GitHub Pages

Begin by following 
[GitHub's documentation](https://docs.github.com/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#choosing-a-publishing-source)
to enable GitHub pages on your repository and select a publishing source.

You can choose to either publish from your `main` branch alongside your project's source code
or a specific branch that you'll use exclusively for your GitHub pages site. 

Either way, you should choose the option to publish from the `/docs`
subdirectory instead of the default option to publish from your repository's root.

Next, clone the repository you just configured for GitHub pages and checkout
the branch you chose as a publishing source.

    $ git clone [repository-url]
    $ cd [repository-name]
    $ git checkout [gh-pages-branch]

## Understanding your Project's Configuration

Now that you've set up a local clone of the repository you'll be publishing documentation from,
you can build your Swift-DocC documentation site.

> Tip: Before invoking the Swift-DocC plugin, you'll need to add it as a dependency of your package,
>      see <doc:Getting-Started-with-the-Swift-DocC-Plugin> for details.

Before running the `swift package generate-documentation` command, you'll need to know two things.

1. What is the **base path** your documentation will be published at?
   
    This differs based on the 
    [type of GitHub Pages site you have](https://docs.github.com/pages/getting-started-with-github-pages/about-github-pages#types-of-github-pages-sites) 
    but is _almost_ always the name of your GitHub repository. 

    Your documentation site will be published at something like

    ```txt
    https://<username>.github.io/<repository-name>
    ```

    and Swift-DocC needs to know about any base path after the `github.io` portion in order
    to correctly configure relative links. In the above case, that would be `<repository-name>`.

2. Which **target** in your Swift Package would you like to publish documentation for?

    Swift-DocC can build documentation for a single target at a time. When publishing documentation,
    you should select one target per documentation site.

Once you've determined your hosting **base path** and Swift Package **target**, you're ready to
generate documentation.

## Generating the Documentation Site

To build documentation for your site and send the output to the `/docs` directory at the root
of the repository you cloned to host your documentation, run the following **from the root
of the Swift package you want to generate documentation from**:

    $ swift package --allow-writing-to-directory [path-to-docs-directory] \
        generate-documentation --target [target-name] \
        --disable-indexing \
        --transform-for-static-hosting \
        --hosting-base-path [hosting-base-path] \
        --output-path [path-to-docs-directory]

Here's a mapping of the tokens in the above command to what they should be replaced with:

| Token                      | Description                                                                                                    |
|----------------------------|----------------------------------------------------------------------------------------------------------------|
| `[path-to-docs-directory]` | The path to the `/docs` directory at the root of the repository you configured for publishing to GitHub pages. |
| `[target-name]`            | The name of the Swift Package target you'd like to build documentation for.                                    |
| `[hosting-base-path]`      | The base path your website will be hosted at. Most likely this will be the name of your GitHub repository.     |


## Publishing the Documentation Site

To publish your documentation site, commit and push the changes in the repository and
branch you configured for publishing to GitHub Pages.

    $ cd [path-to-github-pages-repository]
    $ git add docs
    $ git commit -m "Update GitHub pages documentation site."
    $ git push

Once the push completes, the documentation site will be available at:

    https://<username>.github.io/<repository-name>/documentation/<target-name>

<!-- Copyright (c) 2022 Apple Inc and the Swift Project authors. All Rights Reserved. -->
