
module Illuminati
  class HtmlElement
    attr_accessor :tag, :content, :children, :parent
    def initialize tag
      self.tag = tag
      self.content = ""
      self.children = []
      self.parent = nil
    end

    def add child
      self.children << child
      child.parent = self
    end

    def each
      self.children.each do |child|
        yield child
      end
    end

    def to_h
      hash = {}
      hash[:tag] = self.tag
      hash[:content] = self.content
      hash[:children] = self.children.collect {|child| child.to_h} unless self.children.empty?
      hash
    end

    def find tag
      found = []
      self.each do |child|
        if child.tag == tag
          found << child
        end
        found.concat(child.find(tag))
      end
      found
    end

    def contains? tag
      contains = false
      self.each do |child|
        if child.tag == tag
          contains = true
          return contains
        end
        contains = child.contains?(tag)
      end
      contains
    end

    def content_for_all tag
      content = []
      fields = self.find(tag)
      if !fields.empty?
        content = fields.collect {|t| t.content}
      end
      content
    end
  end

  class HtmlDoc
    attr_accessor :root, :raw
    EXCLUDE = ["col", "div", "br", "link", "!DOCTYPE", "html"]
    def initialize string
      self.raw = string
      self.root = nil
      self.parse
    end

    def parse
      pos = 0
      current = nil
      while pos < self.raw.size
        previous_content, end_location, tag, is_closing = next_tag(self.raw, pos)
        if !end_location
          #puts 'error no end'
          break
        end
        pos += end_location
        #puts tag
        if !current
          if EXCLUDE.include?(tag)
            #puts "pre excluding #{tag}"
          elsif !is_closing
            #puts "root #{tag}"
            root = HtmlElement.new(tag)
            self.root = root
            current = self.root
          else
            puts "error no current but closing: #{tag}"
          end
        else
          #puts "content: #{previous_content}"
          current.content = previous_content
          if EXCLUDE.include?(tag)
            #puts "excluding #{tag}"
          elsif current.tag == tag and is_closing
            #puts "closing #{tag}"
            current = current.parent
          elsif !is_closing
            element = HtmlElement.new(tag)
            current.add element
            current = current.children[-1]
          else
            puts "error #{tag} #{"is closing" if is_closing}\ncurrent: #{current.tag}"
          end
        end
      end
    end

    def next_tag string, starting = 0
      location = string[starting..-1] =~ /<(\/?)((?:"[^"]*"['"]*|'[^']*'['"]*|[^'">])+)>/
      if location
        content = string[starting..(starting + location - 1)].chomp
        total_tag = $2
        tag = total_tag.split(" ")[0]
        closing = $1 == "/"
        location += total_tag.length + 2
        location += 1 if closing
        return [content,location, tag, closing]
      end
      [nil,nil,nil,nil]
    end

    def to_h
      self.root.to_h
    end

    def find tag
      self.root.find(tag)
    end

  end
end

module Illuminati
  class HtmlParser
    def combine_tables tables
      sample_data = []
      tables.each_with_index do |table, index|
        if is_sample_table?(table)
          table.each do |sample|
            read = ([1,3].include? index) ? 1 : 2
          end
        end
      end
    end


    def is_sample_table? table
      !table[0]["Sample"].nil?
    end

    def parse_file filename
      file_string = File.open(filename, 'r').read
      html_doc = parse_html(file_string)
    end

    def parse_html string
      HtmlDoc.new(string)
    end

    def parse_tables doc
      data = []
      tables = doc.find('table')
      headers = []
      next_has_headers = false
      tables.each do |table|
        if next_has_headers
          if !table.contains?('th')
            table_data = apply_headers(headers, table)
            data << table_data
          else
            puts 'error: next table has headers'
          end
            headers = []
            next_has_headers = false
        end
        if table.contains?('th')
          headers = extract_headers(table)
        else
          headers = []
        end
        if !headers.empty? and table.contains?('td')
          # assume that the headers are meant for the
          # current table
          table_data = apply_headers(headers, table)
          data << table_data
        elsif !headers.empty?
          # the headers are meant for the next table
          next_has_headers = true
        end
      end
      data
    end
  private
    def apply_headers headers, table
      data = []
      if headers.empty?
        puts "error: headers empty"
      else
        # headers are assumed to be keys to each td in the 
        # following table
        rows = table.find('tr')
        rows.each do |row|
          values = row.content_for_all('td')
          data_hash = {}
          values.each_with_index do |value, index|
            data_hash[headers[index]] = value
          end
          data << data_hash
        end
      end
      data
    end

    def extract_headers table
      trs = table.find('tr')
      trs[-1].content_for_all('th')
    end
  end
end

