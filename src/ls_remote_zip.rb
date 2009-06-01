#!/usr/bin/env ruby
#
# This script gets the list of files contained in a remote ZIP file without
# the need to download the entire file.
# 
# The ZIP file must be served by a HTTP server accepting the Range header.
#

require 'zip/zip'
require 'net/http'
require 'yaml/stringio'

include Zip

def cdir_offset(io)
  cdir = ZipCentralDirectory.new
  cdir.read_e_o_c_d(io)
  return cdir.instance_variable_get(:@cdirOffset)
end

def entries_from_cdir(io)
  cdir = ZipCentralDirectory.new
  cdir.read_e_o_c_d(io)

  n_entries = cdir.instance_variable_get(:@size)

  io.seek(0, IO::SEEK_SET)

  entrySet = ZipEntrySet.new
  n_entries.times { entrySet << ZipEntry.read_c_dir_entry(io) }

  return entrySet.instance_variable_get(:@entrySet)
end

def print_entries(entries)
  entries.each_pair do |filename, zip_entry|
    puts "#{filename} #{zip_entry.size}"
  end
end

def entries_from_uri(uri)
  uri = URI.parse(uri)
  
  Net::HTTP.start(uri.host, uri.port) do |http|
    response = http.head(uri.path)
    if response.kind_of? Net::HTTPOK
      length = response['Content-Length']

      trail = http.get(uri.path, 'Range' => 'bytes=-280').body
      trail = StringIO.new(trail)
      offset = cdir_offset(trail)

      cdir = http.get(uri.path, 'Range' => "bytes=#{offset}-").body
      cdir = StringIO.new(cdir)
      entries = entries_from_cdir(cdir)

      return entries
    end
  end

  return nil
end

if __FILE__ == $0
  #uri = URI.parse "http://app.dcc.ufba.br/~rodrigo/zipruby.zip"
  uri = URI.parse ARGV[0] #"http://ufpr.dl.sourceforge.net/sourceforge/jboss/jboss-5.1.0.GA-jdk6.zip"
  
  Net::HTTP.start(uri.host, uri.port) do |http|
    response = http.head(uri.path)
    if response.kind_of? Net::HTTPOK
      length = response['Content-Length']

      STDERR.puts "Length: #{length}"

      trail = http.get(uri.path, 'Range' => 'bytes=-280').body
      trail = StringIO.new(trail)
      offset = cdir_offset(trail)

      STDERR.puts "Offset: #{offset}. Size = #{length.to_i - offset.to_i}"

      cdir = http.get(uri.path, 'Range' => "bytes=#{offset}-").body
      cdir = StringIO.new(cdir)
      entries = entries_from_cdir(cdir)

      STDERR.puts "Number of files: #{entries.size}"

      print_entries entries
    end
  end
end
