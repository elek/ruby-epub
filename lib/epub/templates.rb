=begin

Copyright 2008 Arachne Jericho <arachne.jericho@gmail.com>

This file is part of RubyEpub.

RubyEpub is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

RubyEpub is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with RubyEpub.  If not, see <http://www.gnu.org/licenses/>.

=end
=begin rdoc

Convenience template writing methods.

=end
module Epub
    module Templates
        # Creates an ePub-standards compliant template 
        # HTML file.
        #
        # TODO: Maybe add parameter for a stylesheet to include
        #
        # Parameters:
        # - file : IO object to write to
        # - title : title for the HTML file
        def Templates.writeHtmlTemplate(file, title)
            file.puts <<-END
<?xml version="1.0" encoding="UTF-8" ?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>#{title}</title> 
  </head>
  <body>
    <h1>#{title}</h1>
  </body>
</html>
            END
        end
    end
end

