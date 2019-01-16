#!/usr/bin/env ruby
Version = [1, 0, 0]

require 'optparse'
require 'ostruct'
require 'httparty'
require 'rest-client'
require 'pp'

class EzTag
  include HTTParty
  attr_reader :options
  format :json

  def verbose_puts(str)
    puts str if @options.verbose
  end

  def verify_command
    if @command.nil? || !%w(u d upload download).include?(@command.downcase)
      STDERR.puts "Error: unknown command '#{@command}'"
      exit
    else
      @command = @command.downcase
      @command = "upload" if @command == "u"
      @command = "download" if @command == "d"
    end
    verbose_puts "Command : #{@command}" 
  end

  def verify_path
    if @path.nil? || !File.exist?(@path)
      STDERR.puts "Error: path (#{@path}) does not exist"
      exit
    end

    if !File.directory?(@path)
      STDERR.puts "Error: path (#{@path}) is not directory"
      exit
    end
    verbose_puts "Path : #{@path}" 
  end

  def load_keyfile
    begin
      @key = File.open(@options.keyfile, &:readline)
    rescue Errno::ENOENT
      STDERR.puts "Error: keyfile '#{@options.keyfile}' does not exist"
      exit
    end
    verbose_puts "API Key : #{@key}" 
  end

  def init_http_request
    @uri = "http://#{@options.host}:#{@options.port}"
    self.class.base_uri @uri
    self.class.headers 'Accept' => 'application/json'
    self.class.headers 'Content-Type' => 'application/json'
    self.class.headers 'x-api-key' => @key
    @headers = {
      "Accept" => "application/json",
      "x-api-key" => @key
    }
    verbose_puts "URI : #{@uri}" 
  end

  def verify_user_collection
    get_user unless @options.email.nil? 
    if @options.user_id.nil?
      STDERR.puts "Error: user id or email is required"
      exit
    end
    verbose_puts "User : #{@options.user_id}" 

    get_collection unless @options.collection_name.nil? 
    verbose_puts "Collection : #{@options.collection_id}" 
  end

  def download_file(did, url)
    fullpath = File.join(@path, "#{did}.xml")
    puts "Download <#{@uri}#{url}> to <#{fullpath}>"
    File.open(fullpath, "w") do |file|
      file.binmode
      self.class.get(url, stream_body: true) do |fragment|
        file.write(fragment)
      end
    end
    @success += 1
  end

  def initialize(args)
    @success = 0
    self.parse(args)
    verbose_puts "Option: #{@options.to_h}"
    @command = args[0]
    @path = args[1]

    verify_command
    verify_path
    load_keyfile

    init_http_request
    verify_user_collection
  end

  def download
    documents = get_documents
    documents.each do |d|
      download_file(d[:did], d[:url])
    end
  end

  def upload_file(filename)
    if !@options.force_upload
      did = File.basename(filename, ".xml")
      verbose_puts "  > Checking DID #{did} exist?..."
      response = self.class.get("/collections/#{@options.collection_id}/documents", query: {did: did})
      if !response.to_a.empty?
        puts "Skip <#{filename}>"
        return
      end
    end
    puts "Upload <#{fullpath}> to <#{@uri}/collections/#{@options.collection_id}/documents>"
    RestClient.post("#{@uri}/collections/#{@options.collection_id}/documents",  
      {file: File.new(filename, 'rb')}, 
      headers = @headers
    )
    @success += 1
  end

  def upload
    verbose_puts "Searching directory <#{@path}> for upload..."
    Dir[File.join(@path, "*.xml")].each do |filename|
      upload_file(filename)
    end

  end

  def run
    if @command == "download"
      self.download
    end

    if @command == "upload"
      self.upload
    end

    puts "Total #{@success} files have been transfered"
  end

  def get_user
    verbose_puts "> HTTP Get /users?email=#{@options.email}" if @options.verbose
    response = self.class.get('/users', {query: {email: @options.email}})
    verbose_puts "  --> Response #{response.code}" if @options.verbose
    if response.to_a.empty? 
      STDERR.puts "Error: email(#{@options.email}) does not exist or is not accessible to you"
      exit
    end
    user = response.to_a[0]
    if !@options.user_id.nil? && user["id"] != @options.user_id
      STDERR.puts "Error: user's id(#{@options.user_id}) and email(#{@options.email}) do not match"
      exit
    end
    @options.user_id = user["id"]
  end

  def get_collection
    verbose_puts "> HTTP Get /users/#{@options.user_id}/collections" if @options.verbose
    response = self.class.get("/users/#{@options.user_id}/collections", {query: {name: @options.collection_name}})
    verbose_puts "  --> Response #{response.code}: #{response.to_a.inspect}" if @options.verbose
    if response.to_a.empty? 
      STDERR.puts "Error: collection(#{@options.collection_name}) does not exist or is not accessible to you"
      exit
    elsif response.to_a.size > 1 
      STDERR.puts "Error: there are multiple collections with the same name (#{@options.collection_name})"
      exit
    end

    collection = response.to_a[0]
    if !@options.collection_id.nil? && collection["id"] != @options.collection_id
      STDERR.puts "Error: collection's id(#{@options.collection_id}) and name(#{@options.collection_name}) do not match"
      exit
    end
    @options.collection_id = collection["id"]
  end
  
  def get_documents
    verbose_puts "> HTTP Get /collections/#{@options.collection_id}/documents" if @options.verbose
    response = self.class.get("/collections/#{@options.collection_id}/documents")
    verbose_puts "  --> Response #{response.code}: #{response.to_a.inspect}" if @options.verbose
  
    @documents = response.to_a.map{|d| {did: d["did"], url: "/documents/#{d["id"]}.xml"}}
  end

  def parse(args)
    @options = OpenStruct.new
    @options.verbose = false
    @options.host = "eztag.bioqrator.org"
    @options.port = 80
    @options.keyfile = "./apikey"
    @options.force_upload = false
    opt_parser = OptionParser.new do |opts|

      opts.banner = "Usage: eztag.rb COMMAND [options] path"

      opts.separator ""
      opts.separator "Commands:"
      opts.separator "   u / upload      Upload BioC files in the path to user's collection"
      opts.separator "   d / download    Download documents in user's collection into the path"
      opts.separator ""
      opts.separator "Options:"

      # Boolean switch.
      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        @options.verbose = v
      end

      opts.on("-f", "--[no-]force-upload", "Upload duplicate documents even if they have the same PMID") do |v|
        @options.force_upload = v
      end

      opts.on("-h", "--host=HOST", "Hostname for the server (default: eztag.bioqrator.org)") do |v|
        @options.host = v
      end

      opts.on("-p", "--port=PORT", Integer, "Port number for the server (default: 80)") do |v|
        @options.port = v
      end

      opts.on("-k", "--keyfile=KEY_FILE_PATH", "API key file path (default: ./apikey)") do |v|
        @options.keyfile = v
      end

      opts.on('-u', '--user=USER_EMAIL', "User email") do |email|
        @options.email = email
      end

      opts.on('-U', '--user_id=USER_ID', Integer, "User ID") do |id|
        @options.user_id = id
      end

      opts.on('-c', '--col=COLLECTION_NAME', "Collection name") do |name|
        @options.collection_name = name
      end

      opts.on('-C', '--col_id=COLLECTION_ID', Integer, "Collection ID") do |id|
        @options.collection_id = id
      end

      opts.separator ""
      opts.separator "Common options:"
      # No argument, shows at tail.  This will print an options summary.
      # Try it and see!
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

        # Another typical switch to print the version.
      opts.on_tail("--version", "Show version") do
        puts ::Version.join('.')
        exit
      end
    end
    args << '-h' if args.empty?
    opt_parser.parse!(args)
    @options
  end

end

eztag = EzTag.new(ARGV)
eztag.run
