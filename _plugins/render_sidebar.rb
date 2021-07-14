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

    def subdirectory_links(subdirectories)
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
        links += subdir.directory
        links += "</a>"
        links += "<ul>" # _toctree.liquid
        subdir.pages.each do |page|
          links += "<li class=\"toc level-#{subdir.depth}\" data-sort=\"#{page.sort}\" data-level=\"#{subdir.depth}\">"
          links += "<a class=\"d-flex flex-items-baseline\" href=\"#{abs_dir_path}#{page.page}\">"
          links += (page.sort != nil ? "#{page.sort}. " : "") + page.title
          links += "</a></li>"
        end
        links += "<li class=\"toc level-#{subdir.depth}\">"
        links += subdirectory_links(subdir.subdirectories)
        links += "</li>"
        links += "</ul>" # _toctree.liquid end
      end
      links
    end

    def render_sidebar(root)
      # ROOT PAGES - LEVEL 0
      sidebar = "<ul>" # toctree.liquid start
      root.pages.each do |page|
        sidebar += top_level_page_link(page, root)
      end
      sidebar += "</ul>" # toctree.liquid end
      sidebar += subdirectory_links(root.subdirectories)
      sidebar
    end

    def render(context)
      urls_json = lookup(context, 'site_files_urls_json')
      titles_json = lookup(context, 'site_files_titles_json')
      sort_json = lookup(context, 'site_files_sort_json')
      urls = JSON.parse(urls_json)
      titles = JSON.parse(titles_json)
      sort = JSON.parse(sort_json)
      root = Node.new(0, "")
      paths = []
      (0..urls.length - 1).each do |i|
        paths << Path.new(urls[i], titles[i], sort[i])
      end
      paths.each do |path|
        root.add_file_path(path)
      end
      render_sidebar(root)
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

    def print_paths(node)
      print_pages(node)
      if node.subdirectories.length > 0
        node.subdirectories.each do |subdirectory|
          print_paths(subdirectory)
        end
      end
    end

    def print_pages(node)
      node.pages.each do |page|
        puts node.absolute_dir_path + page
      end
    end
  end

  def test
    root = Node.new(0, "")
    root.add_file_path("/rootfile.html")
    root.add_file_path("/foo/foo.html")
    root.add_file_path("/bar/bar.html")
    root.add_file_path("/a/b/c/d2.html")
    root.add_file_path("/a/b/c/d1.html")
    root.add_file_path("/a/aa/aaa/aaaa.html")
    root.add_file_path("/a/aa.html")
    puts "PRINTING NODE"
    puts root
    puts "PRINTING ITEMS"
    puts root.collect_items("")
    puts "PRINTING PATHS"
    root.print_paths(root)
  end

  # test
end

Liquid::Template.register_tag('render_sidebar', Jekyll::RenderSidebar)

