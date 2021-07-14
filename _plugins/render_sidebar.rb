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

    def top_level_page_link(page, root)
      link = "<li class=\"toc level-#{root.depth}\" data-sort=\"#{page.sort}\" data-level=\"#{root.depth}\">"
      link += "<a class=\"d-flex flex-items-baseline\" href=\"/#{page.page}\">#{page.title}</a>"
      link += "</li>"
      link
    end

    def subdirectory_links(subdirectories, dir_to_title)
      links = ""
      subdirectories.each do |subdir|
        abs_dir_path = subdir.absolute_dir_path
        if subdir.depth == 1
          # SUBDIRECTORIES - LEVEL 1
          links += "<a class=\"caption d-block text-uppercase no-wrap px-2 py-0\" href=\"#{abs_dir_path}\">"
        else
          # SUBDIRECTORIES - LEVEL 2+
          links += "<a class=\"d-flex flex-items-baseline\" href=\"#{abs_dir_path}\">"
        end
        links += dir_to_title[subdir.absolute_dir_path] != nil ? dir_to_title[subdir.absolute_dir_path] : subdir.directory
        links += "</a>"
        links += "<ul>" # _toctree.liquid
        subdir.pages.each do |page|
          links += "<li class=\"toc level-#{subdir.depth}\" data-sort=\"#{page.sort}\" data-level=\"#{subdir.depth}\">"
          links += "<a class=\"d-flex flex-items-baseline\" href=\"#{abs_dir_path}#{page.page}\">"
          links += (page.sort != nil ? "#{page.sort}. " : "") + page.title
          links += "</a></li>"
        end
        links += "<li class=\"toc level-#{subdir.depth}\">"
        links += subdirectory_links(subdir.subdirectories, dir_to_title)
        links += "</li>"
        links += "</ul>" # _toctree.liquid end
      end
      links
    end

    def render_sidebar(root, dir_to_title)
      # ROOT PAGES - LEVEL 0
      sidebar = "<ul>" # toctree.liquid start
      root.pages.each do |page|
        sidebar += top_level_page_link(page, root)
      end
      sidebar += "</ul>" # toctree.liquid end
      sidebar += subdirectory_links(root.subdirectories, dir_to_title)
      sidebar
    end

    def render(context)
      # directory paths, e.g. ["/","/test_long/folder1/","/test_long/folder1/folder2/"...]
      dirs_dirs_json = lookup(context, 'site_dirs_dirs_json')
      # directory titles, e.g. [null,"I’m folder1","I’m folder2",...]
      dirs_titles_json = lookup(context, 'site_dirs_titles_json')
      dirs_dirs = JSON.parse(dirs_dirs_json)
      dirs_titles = JSON.parse(dirs_titles_json)
      dir_to_title = {}
      (0..dirs_dirs.length - 1).each do |i|
        dir_to_title[dirs_dirs[i]] = dirs_titles[i]
      end
      root = Node.new(0, "")
      # file urls, e.g. ["/about.html","/contactus.html","/test_long/folder1/file1.html"...]
      urls_json = lookup(context, 'site_files_urls_json')
      # file titles, e.g. ["About","Contact Us","file1"...]
      titles_json = lookup(context, 'site_files_titles_json')
      # file sort, e.g. [null,null,null,...,9,10,11]
      sort_json = lookup(context, 'site_files_sort_json')
      urls = JSON.parse(urls_json)
      titles = JSON.parse(titles_json)
      sort = JSON.parse(sort_json)
      paths = []
      (0..urls.length - 1).each do |i|
        paths << Path.new(urls[i], titles[i], sort[i])
      end
      paths.each do |path|
        root.add_file_path(path)
      end
      render_sidebar(root, dir_to_title)
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

