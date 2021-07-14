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

    def top_level_page_link(page)
      link = "<li class=\"toc level-1\" data-sort=\"1\" data-level=\"1\">"
      link += "<a class=\"d-flex flex-items-baseline\" href=\"/#{page}\">#{page}</a>"
      link += "</li>"
      link
    end

    def subdirectory_links(subdirectories)
      links = ""
      subdirectories.each do |subdir|
        # links += "<div>sub: #{subdir}</div>"
        # if this is a directory
        # if subdir.pages.length == 0
        abs_dir_path = subdir.absolute_dir_path
        if subdir.depth == 1
          # either: SUBDIRECTORIES - LEVEL 1 (-> 2)
          links += "<a class=\"caption d-block text-uppercase no-wrap px-2 py-0\" href=\"#{abs_dir_path}\">#{subdir.directory}</a>"
        else
          # or: SUBDIRECTORIES - LEVEL 2+ (-> 3+)
          links += "<li class=\"toc level-#{subdir.depth + 1}\">"
          links += "<a class=\"d-flex flex-items-baseline\" href=\"#{abs_dir_path}\">#{subdir.directory}</a>"
          links += "</li>"
        end
        links += "<ul>"
        links += subdirectory_links(subdir.subdirectories)
        subdir.pages.each do |page|
          # render link to page
        end
        links += "</ul>"
      end
      links
    end

    def render(context)
      urls_json = lookup(context, 'site_files_urls_json')
      urls = JSON.parse(urls_json)
      root = Node.new(0, "")
      urls.each do |url|
        root.add_file_path(url)
      end
      # ROOT FILES - LEVEL 0 (-> 1)
      sidebar = "<ul>"
      root.pages.each do |page|
        sidebar += top_level_page_link(page)
      end
      sidebar += "</ul>"
      sidebar += subdirectory_links(root.subdirectories)
      # # SUBDIRECTORY 2 ITEMS
      # sidebar += "<li class=\"toc level-2\" data-level=\"2\">"
      # sidebar += "<a class=\"d-flex flex-items-baseline\" href=\"/directory2/file1.html\">file1 level 2</a>"
      # sidebar += "<a class=\"d-flex flex-items-baseline\" href=\"/directory2/file2.html\">file2 level 2</a>"
      # sidebar += "</li>"
      # # SUBDIRECTORY 3+ ITEMS
      # sidebar += "<li class=\"toc level-3\" data-level=\"3\">"
      # sidebar += "<a class=\"d-flex flex-items-baseline\" href=\"/directory3+/file1.html\">file1 level 3+</a>"
      # sidebar += "<a class=\"d-flex flex-items-baseline\" href=\"/directory3+/file2.html\">file2 level 3+</a>"
      # sidebar += "</li>"
      # sidebar += "</ul>"
      sidebar
    end
  end

  require "set"

  class Node
    SEPARATOR = '/'

    attr_reader :depth
    attr_reader :directory
    attr_reader :pages
    attr_reader :subdirectories
    attr_reader :parent

    def initialize(depth, directory, parent = nil)
      @parent = parent
      @depth = depth
      @directory = directory
      @pages = SortedSet.new
      @subdirectories = SortedSet.new
    end

    def add_file_path(path)
      dir_segments = path[1..-1].split(SEPARATOR)
      add_file_path_list(dir_segments)
    end

    def add_file_path_list(dir_segments)
      first = dir_segments[0]
      other = dir_segments[1..-1]
      if other.length == 0
        @pages << first
        return
      end
      @subdirectories.each do |subdirectory|
        if subdirectory.directory == first
          subdirectory.add_file_path_list(other)
          return
        end
      end
      new_subdirectory = Node.new(@depth + 1, first, self)
      @subdirectories << new_subdirectory
      new_subdirectory.add_file_path_list(other)
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

