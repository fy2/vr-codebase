=head1 NAME

VertRes::Utils::Assembly - wrapper for calling assembler and assembly optimiser

=head1 SYNOPSIS

=head1 DESCRIPTION

Provides a uniform interface for assembly so you dont need to worry about the differences between assemblers

=head1 AUTHOR

path-help@sanger.ac.uk

=cut

package VertRes::Utils::Assembly;

use strict;
use warnings;
use VertRes::IO;
use File::Basename;
use VertRes::Utils::Hierarchy;
use VertRes::Utils::FileSystem;
use VRTrack::Lane;

use base qw(VertRes::Base);

=head2 new

 Title   : new
 Usage   : my $obj = VertRes::Utils::Assembly->new();
 Function: Create a new VertRes::Utils::Assembly object.
 Returns : VertRes::Utils::Assembly object
 Args    : assember => 'velvet'|'abyss' 

=cut

sub new {
    my ($class, @args) = @_;
    
    my $self = $class->SUPER::new(@args);

    return $self;
}

=head2 find_module

 Title   : find_module
 Usage   : my $module = $obj->find_module();
 Function: Find out what assembly utility module to use
 Returns : class string (call new on it)

=cut

sub find_module {
    my ($self) = @_;
    return "VertRes::Utils::Assemblers::".$self->{assembler};
}


=head2 generate_files_str

 Title   : generate_files_str
 Usage   : my $module = $obj->generate_files_str();
 Function: create the input string for the files to go into the assembler
 Returns : string which can be passed into assembler

=cut
sub generate_files_str
{
  my $self = shift;
  $self->throw("This is supposed to be overriden");
}



=head2 estimate_memory_required

 Title   : estimate_memory_required
 Usage   : my $memory_required_in_kb = $obj->estimate_memory_required();
 Function: estimate the momory required for the assembler in KB
 Returns : integer in kb of memory requirement

=cut
sub estimate_memory_required
{
  my $self = shift;
  $self->throw("This is supposed to be overriden");
}

=head2 split_reads

 Title   : split_reads
 Usage   : $obj->split_reads('/my_dir',['/path/to/lane1', 'path/to/lane2']);
 Function: Take in a list of lane directories, find the forward and reverse fastqs, and merge them into single forward & reverse fastqs (pool them), 
           so that they can be used as input to other applications.
 Returns : nothing but creates 2 fastq files on disk in the output directory.

=cut
sub split_reads
{
  my ($self, $output_directory, $lane_paths) = @_;
  my $forward_fastq = '';
  my $reverse_fastq = '';
  
  for my $lane_path ( @$lane_paths)
  {
    my ($base_directory,$base,$suff) = Utils::basename($lane_path);
    opendir(my $lane_dir_handle, $base_directory);
    my @fastq_files  = grep { /\.fastq\.gz$/ } readdir($lane_dir_handle);
    if(@fastq_files >=1 )
    {
      $forward_fastq .= $base_directory.'/'.$fastq_files[0];
    }
    if(@fastq_files >=2 )
    {
      $reverse_fastq .= $base_directory.'/'.$fastq_files[1];
    }
  }

  unless( -e "$output_directory/forward.fastq")
  {
    `gzip -cd $forward_fastq  > $output_directory/forward.fastq`;
  }
  unless(-e "$output_directory/reverse.fastq")
  {
    `gzip -cd $reverse_fastq  > $output_directory/reverse.fastq`;
  } 
}

=head2 assembly_directories

 Title   : assembly_directories
 Usage   : my $module = $obj->assembly_directories();
 Function: Find out where the assemlbies are located
 Returns : array of paths

=cut
sub assembly_directories
{
  my $self = shift;
  $self->throw("This is supposed to be overriden");
}


=head2 generate_stats

 Title   : generate_stats
 Usage   : my $module = $obj->generate_stats($directory);
 Function: Generate stats for each fa file in the directory

=cut
sub generate_stats
{
  my ($self, $directory) = @_;
  my @output_files;
  opendir(DIR, $directory);
  my @files = grep {/\.fa$/} readdir(DIR);
  for my $file(@files)
  {
    next unless(-e $directory.'/'.$file);
    system("assembly_stats $directory/$file > $directory/$file.stats");
  }
}



1;
