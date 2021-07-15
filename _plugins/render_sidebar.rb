module Jekyll
  class RenderSidebar < Liquid::Tag

    def initialize(tag_name, text, tokens)
      super
      @text = text
    end

    # Access variable [name] from Liquid.
    def lookup(context, name)
      lookup = context
      name.split(".").each { |value| lookup = lookup[value] }
      lookup
    end

    def top_level_page_link(page, root, current_page_path)
      current = current_page_path == "/#{page.page}" ? "current" : ""
      link = "<li class=\"toc level-#{root.depth + 1} #{current}\" data-sort=\"#{page.sort}\" data-level=\"#{root.depth + 1}\">"
      link += "<a class=\"d-flex flex-items-baseline \" href=\"/#{page.page}\">#{page.title}</a>"
      link += "</li>"
      link
    end

    def subdirectory_links(subdirectories, dir_to_title, current_page_path)
      links = ""
      subdirectories.each do |subdir|
        abs_dir_path = subdir.absolute_dir_path
        if subdir.depth == 1
          # SUBDIRECTORIES - LEVEL 1
          links += "<a class=\"caption d-block text-uppercase no-wrap px-2 py-0\" href=\"#{abs_dir_path}\">"
        else
          # SUBDIRECTORIES - LEVEL 2+
          links += "<li class=\"toc level-#{subdir.depth - 1}\">"
          links += "<a class=\"d-flex flex-items-baseline\" href=\"#{abs_dir_path}\">"
        end
        links += dir_to_title[subdir.absolute_dir_path] != nil ? dir_to_title[subdir.absolute_dir_path] : subdir.directory
        links += "</a>"
        links += "<ul>" # _toctree.liquid
        subdir.pages.each do |page|
          current = current_page_path == "#{abs_dir_path}#{page.page}" ? "current" : ""
          links += "<li class=\"toc level-#{subdir.depth} #{current}\" data-sort=\"#{page.sort}\" data-level=\"#{subdir.depth}\">"
          links += "<a class=\"d-flex flex-items-baseline \" href=\"#{abs_dir_path}#{page.page}\">"
          links += (page.sort != nil ? "#{page.sort}. " : "") + page.title
          links += "</a></li>"
        end
        if subdir.subdirectories.length > 0
          links += subdirectory_links(subdir.subdirectories, dir_to_title, current_page_path)
        end
        links += "</ul>" # _toctree.liquid end
        if subdir.depth > 1
          links += "</li>"
        end
      end
      links
    end

    def render_sidebar(root, dir_to_title, current_page_path)
      # ROOT PAGES - LEVEL 0
      sidebar = "<ul>" # toctree.liquid start
      root.pages.each do |page|
        sidebar += top_level_page_link(page, root, current_page_path)
      end
      sidebar += "</ul>" # toctree.liquid end
      sidebar += subdirectory_links(root.subdirectories, dir_to_title, current_page_path)
      sidebar
    end

    def render(context)
      # path of the currently processed page
      current_page_path = lookup(context, 'page.url')
      site_pages = lookup(context, 'site.html_pages')
      site_pages_directories = site_pages.select { |page| page.dir == page.url }
      site_pages_files = site_pages.select { |page| page.dir != page.url && (!page.url.include? "README.html") }
      # directory paths, e.g. ["/","/test_long/folder1/","/test_long/folder1/folder2/"...]
      # directory titles, e.g. [null,"I’m folder1","I’m folder2",...]
      _dir_to_title = {}
      site_pages_directories.each do |page|
        _dir_to_title[page.dir] = page.data['title']
      end
      # file urls, e.g. ["/about.html","/contactus.html","/test_long/folder1/file1.html"...]
      # file titles, e.g. ["About","Contact Us","file1"...]
      # file sort, e.g. [null,null,null,...,9,10,11]
      _paths = []
      site_pages_files.each do |page|
        if page.url == '/404.html' || page.url == '/search.html'
          next
        end
        _paths << Path.new(page.url, page.data['title'], page.data['sort'])
      end
      root = Node.new(0, "")
      _paths.each do |path|
        root.add_file_path(path)
      end
      render_sidebar(root, _dir_to_title, current_page_path)
    end
  end

  require "set"

  class Path
    attr_reader :path
    attr_reader :title
    attr_reader :sort

    def initialize(path, title, sort)
      @path = path
      @title = title
      @sort = sort
    end

    def to_s
      "Path{" +
        "path=#{@path}" +
        ", title='#{@title}'" +
        ", sort=#{@sort}}"
    end
  end

  class WebPage
    attr_reader :page
    attr_reader :path
    attr_reader :title
    attr_reader :sort

    def initialize(page, path, title, sort)
      @page = page
      @path = path
      @title = title
      @sort = sort
    end

    def <=>(o)
      if sort == nil && o.sort != nil
        1
      elsif sort != nil && o.sort == nil
        -1
      elsif sort != nil && o.sort != nil
        sort <=> o.sort
      else
        @page <=> o.page
      end
    end

    def to_s
      "Page{" +
        "page=#{@page}" +
        ", path='#{@path}'" +
        ", title=#{@title}" +
        ", sort=#{@sort}}"
    end
  end

  class Node
    attr_reader :depth
    attr_reader :directory
    attr_reader :pages
    attr_reader :subdirectories
    attr_reader :parent
    SEPARATOR = '/'

    # TODO: remove @parent and 'absolute_dir_path' and store the directory @path instead
    # TODO: fallback on url if title is absent
    # TODO: support for empty folders
    # TODO: remove redundant liquid files
    def initialize(depth, directory, parent = nil)
      @parent = parent
      @depth = depth
      @directory = directory
      @pages = SortedSet.new
      @subdirectories = SortedSet.new
    end

    def add_file_path(path)
      dir_segments = path.path[1..-1].split(SEPARATOR)
      add_file_path_list(path, dir_segments)
    end

    def add_file_path_list(path, dir_segments)
      first = dir_segments[0]
      other = dir_segments[1..-1]
      if other.length == 0
        @pages << WebPage.new(first, path.path, path.title, path.sort)
        return
      end
      @subdirectories.each do |subdirectory|
        if subdirectory.directory == first
          subdirectory.add_file_path_list(path, other)
          return
        end
      end
      new_subdirectory = Node.new(@depth + 1, first, self)
      @subdirectories << new_subdirectory
      new_subdirectory.add_file_path_list(path, other)
    end

    def absolute_dir_path
      path = directory + SEPARATOR
      node = self
      while node.parent != nil do
        node = node.parent
        path = node.directory + SEPARATOR + path
      end
      path
    end

    def <=>(o)
      @directory <=> o.directory
    end

    def to_s
      "Node{" +
        "depth=#{@depth}" +
        ", directory='#{@directory}'" +
        ", pages=#{@pages}" +
        ", subdirectories=#{@subdirectories}}"
    end
  end

  def test
    root = Node.new(0, "")
  end

  # test
end

Liquid::Template.register_tag('render_sidebar', Jekyll::RenderSidebar)

