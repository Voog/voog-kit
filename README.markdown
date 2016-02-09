# Voog Developer Toolkit

The Voog Designer Toolkit is a simple command-line tool that simplifies the editing
of [Voog](http://www.voog.com) sites. It allows you to pull the layout files to your
own computer and push them back online after you've finished. There are also other
utility commands, described below.

## Installation

Install the Voog toolkit gem:

```bash
$ gem install voog-kit
```

This installs the main tool, `kit`, which is added to your system's $PATH, which
means it can be run from anywhere in your system.


### API token
To use the toolkit, you have to generate your API token from your profile settings 
page (http://yoursite.voog.com/admin/people/profile). 
![generating the API token](https://dl.dropboxusercontent.com/u/10145790/generating_api_token.png)

You should see something like this:

![API token is generated](https://dl.dropboxusercontent.com/u/10145790/api_token_generated.png)

Without this token, *kit* will not allow you to access or change your layout files.

## Basic usage

The most straightforward usage for `kit` is to synchronize layout files between the
live site and your local machine.

After following the voog-kit installation instruction, you set up `kit` and  also generated an API token: `0809d0c93c53438d435b2073d2cf2d22` for your customisite
at `mysite.voog.com`. This is essentially all you need to get started.

### Downloading the layout

`kit pull -h mysite.voog.com -t 0809d0c93c53438d435b2073d2cf2d22` 

This downloads the layout files from *mysite.voog.com* using the API token 
*0809d0c93c53438d435b2073d2cf2d22*. This creates the necessary folders to hold the 
files, so the file structure stays the same as in the online code editor.

The current folder structure should be something like this:
```
./
    assets/
    components/
    images/
    javascripts/
    layouts/
    stylesheets/
```

As you can see, **kit** also generated a *manifest.json* file to hold the metadata to along with
the layout files. This is later used when checking for missing files and uploading everything back up.

There's also a *.voog* file that holds your hostname and API token so you don't have to provide them
every time:

```
[mysite.voog.com]
  host=mysite.voog.com
  api_token=0809d0c93c53438d435b2073d2cf2d22
  overwrite=false
```

The site name inside the square brackets, [mysite.voog.com] is set as a default.
You can change it to whatever you want. If you only have one site to work with within
the current folder, you don't have to worry about it. When you do, however, have multiple
sites with the same layout, it's useful to have meaningful names for each configuration block.

To specify which block to use, you can provide it with the `--site` or `-s` options like so:

`kit pull -s mysite.voog.com`

This looks for a configuration file block with the same name
and uses the hostname and API token given there.

### Uploading the changes

After making the changes, you'll want to upload them to your site. This is done via `kit push`.
The possible arguments are same as before: you can provide the hostname and token manually with
`-h / --host` and `-t / --token`, or just provide the configuration block name found in the *.voog* 
file with the `-s / --site` option.

Let's use the last option: `kit push --site=mysite.voog.com`. This lists all the files
that are updated. By default, all files are updated at once, but if you only made changes to a few, you
can provide them explicitly like so: `kit push stylesheets/main.css javascripts/main.js`. This saves
time (and bandwidth) as there's only a few files being uploaded.

### Automating

As you've learned, pushing and pulling files is super easy, but it's still something you
have to do every time you change something and want to see the changes take place.
To counter this, `kit` provides a handy `watch` command that monitors your local files
and pushes them up if it sees any changes. The arguments to this command are, again, the
same as before. To stop watching, press Ctrl+C.

### HTTP vs HTTPS

If your site is running on HTTPS, you can provide the protocol either as part of the hostname,
e.g `kit pull -h https://mysite.voog.com -t 0809d0c93c53438d435b2073d2cf2d22` — this sets the protocol
option to 'https' and also stores it in the configuration file just like other options — or as a separate
option: `kit pull -h mysite.voog.com -t 0809d0c93c53438d435b2073d2cf2d22 --protocol=https`.

## Commands

* `init`     - Initializes the local folder structure and files for a site
* `manifest` - Generates a `manifest.json` file from the site's layout and asset files
* `check`    - Cross-checks the generated manifest to your local files to see if anything is missing
* `pull`     - Fetches the layout and layout asset files for the given site
* `push`     - Synchronizes your local changes with Voog
* `remove`   - Removes both local and remote files
* `watch`    - Watches for file changes in the current directory
* `help`     - Shows a list of commands or help for one command

Most of these commands use the same options as shown before:
`--site / -s` - provide a configuration block name
`--host / -h` - provide a hostname
`--token / -t` - provide your API token to authorize all requests

Another useful option is `--overwrite` to allow updating asset files you normally couldn't update. This deletes the 
old file and uploads the newer one as a replacement. This cannot be undone, so take caution!
To enable overwriting for all commands, you can add it to the site's configuration block in the `.voog` file like so:

```
[site1]
  host=mysite.voog.com
  api_token=0809d0c93c53438d435b2073d2cf2d22
  overwrite=true
```

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

### remove
`kit remove` first checks if the provided filename is valid, then removes it from the manifest. After that it deletes 
the local file and sends an API request to delete the remote file as well. The directory name must be included in the
file name, e.g **assets/icon.svg** is valid, but **assets/** or **search.svg** is not.

### watch

This command starts a watcher that monitors the current folder and its subfolders and triggers `kit push` every time
a file changes. This is most useful for styling your site as all style changes are instantly uploaded and visible in
the browser.

`watch` also looks for newly created files and file removals, updates the manifest accordingly and triggers `kit push`. 

You can stop the watch command by pressing Ctrl+D or typing "exit" or "q".

### help

This command shows helpful information about the tool or its subcommands. Invoking `kit help` shows a list of possible
options and commands with a brief description. `kit help <command>` shows information about that command.



If you want to explicitly use latest version of the [Voog API client](https://github.com/Edicy/voog.rb):

```bash
$ git pull https://github.com/Edicy/voog.rb voog-api
$ cd voog-api
$ bundle install
$ rake install
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
