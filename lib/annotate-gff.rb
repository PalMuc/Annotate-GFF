#!/usr/bin/env ruby

require 'rubygems'
require 'uri'

require 'trollop'
require 'bio'
require 'nokogiri'

def get_blast_annotations(xml_reader)

	query_hit_map = {}
	current_query = nil
  current_name = nil
  name_species_regexp = /(.*)\s\[(.*)\].*/

	#Go through the XML with a pull-parser
	xml_reader.each do |elem|
		if elem.name == "Iteration_query-def"&& elem.node_type == Nokogiri::XML::Node::ELEMENT_NODE
			#We are at the beginning of an iteration
			current_query = elem.inner_xml
      regexp_match = name_species_regexp.match(current_query)
      unless regexp_match.nil?
        current_name = regexp_match[1]
      else
        current_name = current_query
      end
      
		elsif elem.name == "Hit" && elem.node_type == Nokogiri::XML::Node::ELEMENT_NODE
			#We are at the beginning of a Hit
			#Load the node representing this hit into memory and extract required information
			hit = Nokogiri::XML(elem.outer_xml)
			hit_def = hit.xpath("//Hit_def").inner_text
			hsp_evalue = hit.xpath("//Hsp[1]/Hsp_evalue").inner_text.to_f #Yep, the first element really has number 1

			lowest_evalue_so_far = 9999 #This value does not matter because it will always be set with the evalue of the first hit
			
			#Make sure this map only contains the hits with the lowest evalue
			if !(query_hit_map.has_key? current_name) || (lowest_evalue_so_far > hsp_evalue)
				query_hit_map[current_name] = hit_def
				lowest_evalue_so_far = hsp_evalue
			end
		end
	end

	return query_hit_map
end

def blast_result_to_GFF_records(hits_reader, blast_annotations)
	raise ArgumentError unless hits_reader.is_a? Nokogiri::XML::Reader
	
	blast_output_version = ""
	blast_output_db = ""

	current_iteration = 0
	current_query_name = nil
	current_query_length = 0
	current_hit_def = ""
	current_hit_name = nil
	current_hit_alias = nil
	current_hit_annotation = nil

	feature_type = "EST_match"
	name_species_regexp = /(.*)\s\[(.*)\].*/

	gff_records = {}

	forbidden_characters = ",=;%&\t"
	allowed_in_seqids = /[a-zA-Z0-9.:^*$@!+_?-|]/

	#Go through the XML with a pull-parser
	hits_reader.each do |elem|

		#Ordered by frequency of appearance, not by order of appreance
		#in an attempt to increase performance
		if elem.name == "Hsp" && elem.node_type == Nokogiri::XML::Node::ELEMENT_NODE
			#Load the node representing this hsp into memory and extract required information
			#Write annotation
			hsp = Nokogiri::XML(elem.outer_xml)
			feature_evalue = hsp.xpath("//Hsp_evalue").inner_text.to_f
			feature_from = hsp.xpath("//Hsp_query-from").inner_text.to_i
			feature_to = hsp.xpath("//Hsp_query-to").inner_text.to_i
			feature_strand = nil #hsp.xpath("//Hsp_hit-frame").inner_text.to_i

			feature_attributes = []
			unless current_hit_alias.nil?
				feature_attributes << ["Name", current_hit_name]
				feature_attributes << ["Alias", current_hit_alias]
			else
				feature_attributes << ["Name", current_hit_name]
			end

			#Annotate ESTs with the best hit from BLAST results
			unless current_hit_annotation.nil?
				feature_attributes << ["Note", current_hit_annotation]
			end
			
			new_record = Bio::GFF::GFF3::Record.new(current_query_name, blast_output_version, feature_type, feature_from.to_s, feature_to.to_s, feature_evalue, feature_strand, nil, feature_attributes)
			gff_records[current_query_name] << new_record
      
		elsif elem.name == "Hit_def" && elem.node_type == Nokogiri::XML::Node::ELEMENT_NODE
			#We are at the beginning of a Hit
			current_hit_def = elem.inner_xml
			regexp_match = name_species_regexp.match(current_hit_def)
      
			unless regexp_match.nil?
				current_hit_name = URI.escape(regexp_match[1], forbidden_characters)
				current_hit_alias = URI.escape(regexp_match[2], forbidden_characters)
			else
				current_hit_name = URI.escape(current_hit_def, forbidden_characters)
				current_hit_alias = nil
			end

			#Get annotations from BLAST hits
      search_result = blast_annotations[current_hit_name]
			unless search_result.nil?
				current_hit_annotation = URI.escape(search_result, forbidden_characters)
			else
				current_hit_annotation = nil
			end
			
		elsif elem.name == "Iteration_query-def" && elem.node_type == Nokogiri::XML::Node::ELEMENT_NODE
			#We've got a new query sequence

			#Check if we found any results for the old query sequence
			#Write a dummy annotation for the old query seq if neccessary
			if gff_records.has_key? current_query_name
				if gff_records[current_query_name].empty?
					dummy_feature_attributes = []
					dummy_feature_attributes << ["Note", "No hits for " + URI.escape(blast_output_db, forbidden_characters)]
					new_record = Bio::GFF::GFF3::Record.new(current_query_name, nil, "remark", 1.to_s, current_query_length, nil, nil, nil, dummy_feature_attributes)
					gff_records[current_query_name] << new_record
				end
			else
				#This must be the first query sequence
			end
      
      #Set the new query sequence
      unescaped_query_name = elem.inner_xml
			current_query_name = URI.escape(unescaped_query_name, forbidden_characters + unescaped_query_name.gsub(allowed_in_seqids, "") + ">")
      puts current_query_name

			if gff_records.has_key? current_query_name
				abort "Multiple iterations"
			else
				gff_records[current_query_name] = [] #This array will hold all annotations
			end

		elsif elem.name == "Iteration_query-len" && elem.node_type == Nokogiri::XML::Node::ELEMENT_NODE
			current_query_length = elem.inner_xml.to_i			

		elsif elem.name == "BlastOutput_version" && elem.node_type == Nokogiri::XML::Node::ELEMENT_NODE
			#Get what version of BLAST was used
			blast_output_version = URI.escape(elem.inner_xml, forbidden_characters)
			
		elsif elem.name == "BlastOutput_db" && elem.node_type == Nokogiri::XML::Node::ELEMENT_NODE
			#Get the path of the database
			blast_output_db = URI.escape(elem.inner_xml, forbidden_characters)

		end
		
	end

	return gff_records.values.flatten

end

if RUBY_PLATFORM =~ /java/
  require 'java'
  java_import java.lang.Runtime
  puts "You are running JRuby"
  puts "Max heap memory is: " + (Runtime.get_runtime.maxMemory()/(1024*1024)).to_s
end

opts = Trollop::options do
  opt :input_gff, "Input GFF file", :type => String
  opt :output_gff, "Output GFF file", :type => String
  opt :blast_xml, "Blast XML output", :type => String
  opt :annotation_xml, "Blast XML output for annotations", :type => String
end

unless opts[:input_gff_given] && opts[:output_gff_given] && opts[:blast_xml_given]
  abort "Invalid arguments, see --help for more information."
end

input_gff = File.expand_path(opts[:input_gff])
output_gff = File.expand_path(opts[:output_gff])
blast_xml = File.expand_path(opts[:blast_xml])
annotation_xml = File.expand_path(opts[:annotation_xml]) if opts[:annotation_xml_given]

#Check if directories are valid
[File.dirname(output_gff)].each do |chkdir|
  abort "Invalid directory " + chkdir unless File.directory? chkdir
end

#Check if mandatory files are valid
[input_gff, blast_xml].each do |chkfile|
  abort "Invalid file " + chkfile unless File.file? chkfile
end

#Check if optional files are valid
[annotation_xml].each do |chkfile|
  if opts[:annotation_xml_given] && (!File.file? chkfile)
    abort "Invalid file " + chkfile
  end
end

puts "GFF file at " + input_gff
puts "Annotated GFF file will be written to " + output_gff
puts "XML BLAST output for the placement of ESTs at " + blast_xml
puts "XML BLAST output for the automatic annotation of EST hits at: " + annotation_xml if opts[:annotation_xml_given]

#Open the annotations file
puts "Reading " + input_gff
gfffile = Bio::GFF::GFF3.new(File.new(input_gff))

#Open the annotations BLAST XML output
blast_annotations = {}
if opts[:annotation_xml_given]
  puts "Reading " + annotation_xml
  annotations_reader = Nokogiri::XML::Reader(File.new(annotation_xml))
  blast_annotations = get_blast_annotations(annotations_reader)
end

#Open the BLAST XML search hits
puts "Reading "+ blast_xml
hits_reader = Nokogiri::XML::Reader(File.new(blast_xml))

#Turn BLAST hits into GFF records and add them to the file
new_annotations = blast_result_to_GFF_records(hits_reader, blast_annotations)
gfffile.records.concat(new_annotations)

gff_out = File.open(output_gff, "w")
gff_out.write(gfffile)
gff_out.close

puts "Done!"
