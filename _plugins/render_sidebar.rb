module Jekyll
  class RenderSidebar < Liquid::Tag

    def initialize(tag_name, text, tokens)
      super
      @text = text
    end

    # Lookup allows access to the page/post variables through the tag context
    def lookup(context, name)
      lookup = context
      name.split(".").each { |value| lookup = lookup[value] }
      lookup
    end

    def render(context)
      _htmlPages = lookup(context, 'site.html_pages')
      _paths = _htmlPages.map { |p| FileEntry.new(p.dir, p.url, p.name) }

      _dirsJson = lookup(context, 'site_files_dirs_json')
      _urlsJson = lookup(context, 'site_files_urls_json')
      _namesJson = lookup(context, 'site_files_names_json')
      _titlesJson = lookup(context, 'site_files_titles_json')
      _sortJson = lookup(context, 'site_files_sort_json')
      _dirs = JSON.parse(_dirsJson)
      _urls = JSON.parse(_urlsJson)
      _names = JSON.parse(_namesJson)
      _titles = JSON.parse(_titlesJson)
      _sort = JSON.parse(_sortJson)
      _fileEntries = Array.new
      for i in 0.._dirs.length()-1
        _fileEntries.append(Reference.new(_dirs[i], _urls[i], _names[i], _titles[i], _sort[i]))
      end
      "html pages: #{_paths.join('<br/>')}<br/><br/>REFERENCE:<br/>#{_fileEntries.join('<br/>')}<br/><br/>#{Time.now}"
    end
  end

  class FileEntry
    def initialize(dir, url, name)
      @dir = dir
      @url = url
      @name = name
    end
    def to_s
      "dir: #{@dir}, url: #{@url}, name: #{@name}"
    end
  end

  class Reference
    def initialize(dir, url, name, title, sort)
      @dir = dir
      @url = url
      @name = name
      @title = title
      @sort = sort
    end
    def to_s
      "dir: #{@dir}, url: #{@url}, name: #{@name}, title: #{@title}, sort: #{@sort}"
    end
  end
end

Liquid::Template.register_tag('render_sidebar', Jekyll::RenderSidebar)

