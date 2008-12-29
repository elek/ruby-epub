=begin 
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

