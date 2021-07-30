require 'set'

class PageTree
  attr_reader :depth
  attr_reader :directory
  attr_reader :pages
  attr_reader :subdirectories
  SEPARATOR = '/'

  # TODO: fallback on url if title is absent
  # TODO: support for empty folders
  def initialize(depth, directory, parent_path, path_to_title)
    @depth = depth
    @directory = directory
    @parent_path = parent_path
    @path_to_title = path_to_title
    @pages = SortedSet.new
    @subdirectories = SortedSet.new
  end

  def directory_title
    @path_to_title[directory_path]
  end

  # Adds the page to the to the directory tree structure
  # creating any intermediate directories as necessary.
  # @param [SourcePage] source_page
  def add_file_path(source_page)
    dir_segments = source_page.path[1..].split(SEPARATOR)
    add_file_path_list(source_page, dir_segments)
  end

  def add_file_path_list(source_page, dir_segments)
    first = dir_segments[0]
    other = dir_segments[1..]
    if other.length == 0
      @pages << WebPage.new(first, source_page.path, source_page.title, source_page.sort)
      return
    end
    @subdirectories.each do |subdirectory|
      if subdirectory.directory == first
        subdirectory.add_file_path_list(source_page, other)
        return
      end
    end
    new_subdirectory = PageTree.new(@depth + 1, first, directory_path, @path_to_title)
    @subdirectories << new_subdirectory
    new_subdirectory.add_file_path_list(source_page, other)
  end

  def directory_path
    @parent_path + @directory + SEPARATOR
  end

  # Given a path (e.g. '/foo/bar/page.html') returns the node the page is at (e.g. 'bar').
  # @param [String] path
  def subtree_at(path)
    dir_segments = path.split(SEPARATOR).select { |segment| not segment.empty? and not segment.include? 'html' }
    node = self
    (0..dir_segments.length - 1).each { |i|
      node = node.subdirectories.find { |sub| sub.directory == dir_segments[i] }
      if node == nil
        break
      end
    }
    node
  end

  def <=>(o)
    @directory <=> o.directory
  end

  def to_s
    "PageTree{" +
      "depth=#{@depth}" +
      ", directory='#{@directory}'" +
      ", parent_path='#{@parent_path}'" +
      ", pages=[#{@pages.to_a.map { |p| p.to_s }.join(', ')}]" +
      ", subdirectories=[#{@subdirectories.to_a.map { |s| s.to_s }.join(', ')}]}"
  end
end

class SourcePage
  attr_reader :path
  attr_reader :title
  attr_reader :sort

  def initialize(path, title, sort)
    @path = path
    @title = title
    @sort = sort
  end

  def to_s
    "SourcePage{" +
      "path=#{@path}" +
      ", title='#{@title}'" +
      ", sort=#{@sort}}"
  end
end

class WebPage
  attr_reader :file
  attr_reader :path
  attr_reader :title
  attr_reader :sort

  def initialize(file, path, title, sort = 0)
    @file = file
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
      @file <=> o.file
    end
  end

  def to_s
    "WebPage{" +
      "file=#{@file}" +
      ", path='#{@path}'" +
      ", title=#{@title}" +
      ", sort=#{@sort}}"
  end
end

def dir_path_to_title_map(site_pages)
  site_pages_directories = site_pages.select { |page| page.dir == page.url }
  dir_to_title = {}
  site_pages_directories.each do |page|
    dir_to_title[page.dir] = page.data['title']
  end
  dir_to_title
end

# Uses HTML pages data retrieved from Liquid for generating the page tree.
def prepare_page_tree(context)
  site_pages = lookup(context, 'site.html_pages')
  # directory paths, e.g. ["/","/test_long/folder1/","/test_long/folder1/folder2/"...]
  # directory titles, e.g. [null,"I’m folder1","I’m folder2",...]
  # file urls, e.g. ["/about.html","/contactus.html","/test_long/folder1/file1.html"...]
  # file titles, e.g. ["About","Contact Us","file1"...]
  # file sort, e.g. [null,null,null,...,9,10,11]
  site_pages_files = site_pages.select { |page| page.dir != page.url && (!page.url.include? 'README.html') }
  source_pages = []
  site_pages_files.each do |page|
    if page.url == '/404.html' || page.url == '/search.html'
      next
    end
    source_pages << SourcePage.new(page.url, page.data['title'], page.data['sort'])
  end
  root = PageTree.new(0, "", "", dir_path_to_title_map(site_pages))
  source_pages.each do |source_page|
    root.add_file_path(source_page)
  end
  root
end