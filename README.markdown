# Voog Developer Toolkit

The Voog Designer Toolkit is a simple Ruby script that simplifies the editing
of [Voog site](http://www.voog.com) templates. It acts as a push-pull mechanism that allows you to
fetch all layout files, work on them locally and upload them without having to 
use the browser-based code editor.

## Installation

Install the Voog toolkit gem:

```bash
$ gem install voog-kit
```

This installs the main tool, `kit`, which is added to your system's $PATH, which
means it can be run from anywhere in your system.

If you want to explicitly use latest version of the [Voog API client](https://github.com/Edicy/voog.rb):

```bash
$ git pull https://github.com/Edicy/voog.rb voog-api
$ cd voog-api
$ bundle install
$ rake install
```

## Basic commands

* `init`     - Initializes the local folder structure and files for a site
* `manifest` - Generates a `manifest.json` file from the site's layout and asset files
* `check`    - Cross-checks the generated manifest to your local files to see if anything is missing
* `pull`     - Fetches the layout and layout asset files for the given site
* `push`     - Synchronizes your local changes with Voog
* `watch`    - Watches for file changes in the current directory
* `help`     - Shows a list of commands or help for one command

Most commands need to know your site's URL and you personal API token to properly authorize all
requests. For this you can either provide them with `--token/-t` and `--host/-h` 
flags, e.g `kit pull -t afcf30182aecfc8155d390d7d4552d14 -h mysite.voog.com`. If there's a '.voog' file
present in the current folder, it takes the options from there.

There's also a `--site/-s` argument that is used to choose a configuration block from the `.voog` file.

Example `.voog` file:

```
[site1]
  host=mysite.voog.com
  api_token=afcf30182aecfc8155d390d7d4552d14
[site2]
  host=site2.customdomain.co
  api_token=5d390d7d4552d14afcf30182aecfc815
```

To choose the second block, you can simply use `kit pull -s site2` or `kit pull --site=site2`.
If the site is not provided, **kit** will use the first block defined in the file.
When you provide the host, token and block name, it is then written to the configuration file, overwriting
any identically named blocks or creating a new one, if necessary.

If the configuration file isn't present and you provide the token, hostname and site name manually when invoking a
command, the file is then generated and the options are stored within so you don't have to provide them
later.

### init

This command either initializes an empty folder structure via `kit init empty`, clones the file and folder
structure of the Pripyat design (essentially a design boilerplate) via `kit init new` or uses the provided
hostname and API token to download existing layout files from the given site via just `kit init`.

### manifest

The manifest file is probably the most important file in the layout file structure. It holds metadata for each
and every file which ensures that all layout names and asset types are correct when pushing or pulling files.
`kit manifest` on its own generates a manifest from all current local files. As this is done purely from file
names, some generated data might be incorrect and, as such, may need manual correction.

If you're generating a 
manifest for a site that already has layout files, it would be better to use the `--remote` flag to use remote
data instead. This takes the layout titles and asset content types that are already saved in Voog and mirrors 
them in the manifest. 

### pull

`kit pull` downloads all files from the site provided via the hostname and api_token options (or from the .voog 
file). This overwrites all existing identically named local files.

By giving filenames or layout/component titles as arguments to `kit pull`, it instead downloads only those (and, 
again, overwrites current local files). For example, `kit pull shadow.png MainMenu` would download the file *images/shadow.png*
and the *MainMenu* component.

### push

`kit push` is the counterpart to `pull`. This takes the provided files or folders and uploads them to the provided
site, overwriting existing files. Although `pull` searches by filename, `push` arguments need to be local file paths.
For example, `kit push images/shadow.png layouts/mainmenu.tpl` works, `kit push shadow.png MainMenu` does not.

### watch

This command starts a watcher that monitors the current folder and its subfolders and triggers `kit push` every time
a file changes. This is most useful for styling your site as all style changes are instantly uploaded and visible in
the browser.

`watch` also looks for newly created files and file removals, updates the manifest accordingly and triggers `kit push`. 

You can stop the watch command by pressing Ctrl+D or typing "exit" or "q".

### help

This command shows helpful information about the tool or its subcommands. Invoking `kit help` shows a list of possible
options and commands with a brief description. `kit help <command>` shows information about that command.

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
    .voog
    manifest.json
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
