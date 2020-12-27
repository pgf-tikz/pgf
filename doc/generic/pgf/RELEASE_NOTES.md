Hotfix for handling of TeX conditionals on a path.  We can't forward \relax and
frozen \relax through the parser because there is existing code that relies on
this.

The recommendation is to use expandable conditionals where possible.
