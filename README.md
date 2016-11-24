phoenixtools
============

Tools for [Phoenix PBeM](http://phoenixbse.com).

## Features

phoenixtools provides the following features for players:

* Market report analysis
* Trade and travel routes with order generation
* Base reports including inventories, mass production and item groups with analysis across multiple bases
* Shipping and mining jobs analysis
* Mining and resource production analysis
* Search items and planets by their attributes

## Database

This uses postgresql as the database with default role 'phoenix' and password 'phoenix'. 

You can override this by setting the environment variables PHOENIXTOOLS_DATABASE_USERNAME and PHOENIXTOOLS_DATABASE_PASSWORD or by editing the config/database.yml file.

## Installation

1. Install Ruby (Windows)

    a) Download [RubyInstaller](http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-1.9.3-p545.exe?direct) and install.

    b) Install (Bundler)[http://bundler.io/]

2. Download phoenixtools

3. Install phoenixtools

    a) Windows

        Run install.bat from the root directory of the software.

    b) Mac OS X / Linux

        Run ./install.sh from the root directory of the software.

    This can take some time!

4. Start phoenixtools web server

    a) Windows

        Run run.bat from the root directory of the software.

    b) Mac OS X / Linux

    Run ./run.sh from the root directory of the software.

5. Go to the [homepage](http://localhost:3000)

6. Configure phoenixtools

You will need to enter your Nexus account details including the information obtained from [Personal->XML Access](http://phoenixbse.com/index.php?a=user&sa=xml). Then you press "Configure".

This may take some time as it populates the database based on your political information.

7. You're good to go!

## License

This code is distributed under the terms and conditions of the MIT license.

## Contributing

Fork it and do a pull request.