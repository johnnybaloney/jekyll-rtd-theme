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

    def render(context)
      urls_json = lookup(context, 'site_files_urls_json')
      urls = JSON.parse(urls_json)
      @root = Node.new(0, "")
      urls.each do |url|
        @root.add_file_path(url)
      end
      # @root.collect_items("").map { |item| "#{item.path} (#{item.depth})" }.join("<br/>")
      # ROOT FILES - LEVEL 0 (-> 1)
      sidebar = "<ul>"
      sidebar += "<li class=\"toc level-1\" data-sort=\"1\" data-level=\"1\">"
      sidebar += "<a class=\"d-flex flex-items-baseline\" href=\"/file.html\">file level 1</a>"
      sidebar += "</li>"
      sidebar += "</ul>"
      # either: SUBDIRECTORIES - LEVEL 1 (-> 2)
      sidebar += "<a class=\"caption d-block text-uppercase no-wrap px-2 py-0\" href=\"/directory2/\">directory level 2</a>"
      # SUBDIRECTORY ITEMS
      sidebar += "<ul>"
      sidebar += "<li class=\"toc level-2\" data-level=\"2\">"
      sidebar += "<a class=\"d-flex flex-items-baseline\" href=\"/directory2/file1.html\">file1 level 2</a>"
      sidebar += "<a class=\"d-flex flex-items-baseline\" href=\"/directory2/file2.html\">file2 level 2</a>"
      sidebar += "</li>"
      sidebar += "</ul>"
      # or: SUBDIRECTORIES - LEVEL 2+ (-> 3+)
      sidebar += "<li class=\"toc level-2\">"
      sidebar += "<a class=\"d-flex flex-items-baseline\" href=\"/directory3+/\">directory level 3+</a>"
      sidebar += "<ul>"
      # files at this level
      sidebar += "<li class=\"toc level-3\" data-level=\"3\">"
      sidebar += "<a class=\"d-flex flex-items-baseline\" href=\"/directory3+/file1.html\">file1 level 3+</a>"
      sidebar += "<a class=\"d-flex flex-items-baseline\" href=\"/directory3+/file2.html\">file2 level 3+</a>"
      sidebar += "</li>"
      sidebar += "</ul>"
      sidebar += "</li>"
      @root.collect_items("").each do |item|
      end
      sidebar
    end
  end

  require "set"

  class Node
    SEPARATOR = '/'

    attr_reader :directory

    def initialize(depth, directory)
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
      new_subdirectory = Node.new(@depth + 1, first)
      @subdirectories << new_subdirectory
      new_subdirectory.add_file_path_list(other)
    end

    def collect_items(parent)
      items = SortedSet.new
      current_dir_abs_path = parent + @directory + SEPARATOR
      items.add(Item.new(true, @directory, current_dir_abs_path, @depth))
      @pages.each do |page|
        items.add(Item.new(false, page, current_dir_abs_path + page, @depth))
      end
      @subdirectories.each do |subdirectory|
        items.merge(subdirectory.collect_items(current_dir_abs_path))
      end
      items
    end

    def <=>(o)
      @directory <=> o.directory
    end

    def to_s
      "Node{" +
        "level=#{@depth}" +
        ", directory='#{@directory}'" +
        ", pages=#{@pages}" +
        ", subdirectories=#{@subdirectories}}"
    end
  end

  class Item

    attr_reader :path
    attr_reader :depth

    def initialize(is_directory, name, path, depth)
      @is_directory = is_directory
      @name = name
      @path = path
      @depth = depth
    end

    def <=>(o)
      @path <=> o.path
    end

    def to_s
      "Item{" +
        "is_directory=#{@is_directory}" +
        ", name='#{@name}'" +
        ", path='#{@path}'" +
        ", depth=#{@depth}}"
    end
  end

  def test
    @root = Node.new(0, "")
    @root.add_file_path("/foo.html")
    @root.add_file_path("/rootfile.html")
    @root.add_file_path("/foo/foo.html")
    @root.add_file_path("/bar/bar.html")
    @root.add_file_path("/a/b/c/d2.html")
    @root.add_file_path("/a/b/c/d1.html")
    @root.add_file_path("/a/a/a/a.html")
    puts "PRINTING NODE"
    puts @root
    puts "PRINTING ITEMS"
    puts @root.collect_items("")
    puts "PRINTING ITEMS with JOIN"
    puts @root.collect_items("").map { |item| "#{item.path} (#{item.depth})" }.join("<br/>")
  end

  # test
end

Liquid::Template.register_tag('render_sidebar', Jekyll::RenderSidebar)

