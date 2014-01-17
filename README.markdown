# Edicy Designer Toolkit

The Edicy Designer Toolkit is a simple Ruby script that simplifies the editing
of Edicy site templates. It acts like a local 'previewmode' emulator by generating
static HTML files of all pages of a site. All Admin-specific logic is excluded for now.
It watches the local directory with the help of Guard and recompiles the files on
every change.

## Installation

Install the gem manually:

    $ gem install edicy-dtk

The main tool is called **edicy** and is added to your system's $PATH automatically
on installation. This means it can be run from anywhere in your system.

One major requirement is the [Ruby wrapper for the Edicy API](https://github.com/Edicy/edicy.rb).
As this is not publicly available just yet, you'll have to install it manually.
As long as the API gem is installed, the edicy-dtk gem should work just fine.

## Basic commands

* `init`     - Initializes the local folder structure and files for a site
* `manifest` - Generates a manifest.json file from the site's layout and asset files
* `build`    - Renders all pages into static .html files
* `pull`     - Fetches the layout and layout asset files for the given site
* `push`     - Synchronizes your local changes with Edicy
* `watch`    - Watches for file changes in the current directory
* `help`     - Shows a list of commands or help for one command

In addition, some commands take the site URL and API token as arguments. If none 
are provided, the tool looks for a '.edicy' file in the current folder that should provide the arguments.
Example .edicy file:
```
[OPTIONS]
  site=mysite.edicy.com
  api_token=afcf30182aecfc8155d390d7d4552d14
```
The file is generated and the arguments are stored within to prevent having to provide them for 
future invocations of the tool.

### init

Initializes the project folder for a given Edicy site. First it fetches the site structure and contents 
(to be implemented) and then downloads the layout files and creates the corresponding folders for them.

### manifest
If the layout files are acquired elsewhere or created on the spot, this command creates a 'manifest.json'
file for those files. The file should be manually checked before proceeding to sync with Edicy as not all
parameters can be guessed from only the file/folder name.

### build
This command finds all pages for the current site from a .json file (to be determined) and compiles a corresponding
.html file for them. All admin-specific logic is ignored while compiling, essentially making it a previewmode emulator.

### pull
(Re-)fetches all layout files from Edicy, replacing the local files with remote versions (to be determined).

### push
Synchronizes local changes with Edicy, uploading your local changes to your website.

### watch
This command constantly watches your local folder and subfolders for any changes and recompiles all .html files
if any layout files change.

### Sample local folder structure
```
./
    assets/
        custom_font.woff
    components/
        mainmenu.tpl
        sidebar.tpl
        footer.tpl
    images/
        background.jpg
    javascripts/
        custom_script.js
        spinner.js
    layouts/
        front_page.tpl
        blog.tpl
        products.tpl
    stylesheets/
        style.css
    .edicy
    manifest.json
    site.json
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
