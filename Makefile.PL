use ExtUtils::MakeMaker;
use Config;
use Devel::CheckLib qw(check_lib_or_exit);
use ExtUtils::F77;

our %ldloadlibs = ($^O =~ /MSWin/ && $Config{cc} eq 'cl')
  ? (LDLOADLIBS => 'oldnames.lib kernel32.lib user32.lib gdi32.lib winspool.lib  comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib  netapi32.lib uuid.lib wsock32.lib mpr.lib winmm.lib  version.lib odbc32.lib odbccp32.lib msvcrt.lib  ../lapack/libacml.lib "C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\lib\msvcrt.lib" ')
  : ();
our $libs0 = (
  eval {require PkgConfig; join ' ', PkgConfig->find('lapack')->get_ldflags} ||
  eval {require ExtUtils::PkgConfig; ExtUtils::PkgConfig->libs('lapack')} ||
  `pkg-config lapack blas --libs` ||
  '-L/usr/lib/atlas -llapack -lblas -latlas'
) . ' ' . ExtUtils::F77->runtime;
{
  # work around Devel::CheckLib not doing Text::ParseWords::shellwords
  my (@lib, @libpath);
  use Text::ParseWords qw(shellwords);
  for (shellwords $libs0) {
    if (s/^-L//) {
      push @libpath, $_;
    } elsif (s/^-l//) {
      push @lib, $_;
    } else {
      # hope is xxx.lib
      s/\W.*//;
      push @lib, $_;
    }
  }
use Carp; use Test::More; diag "RUN ", Test::More::explain [ $libs0, \@lib, \@libpath ];
  check_lib_or_exit(
debug => 1,
    lib => \@lib,
    libpath => \@libpath,
    header => [($^O =~ /MSWin/ ? 'float.h' : ()), 'math.h>
static long c_zero = 0;
static long c_nine = 9;
extern long ilaenv_(long *ispec, char *name__, char *opts, long *n1,
  long *n2, long *n3, long *n4, long name_len, long opts_len); //'],
    function => <<'EOF',
  (void)ilaenv_(&c_nine, "SGESDD", " ", &c_zero, &c_zero, &c_zero, &c_zero, (long)6, (long)1);
EOF
  );
}

WriteMakefile(
  NAME => 'PDL::LinearAlgebra',
  ABSTRACT => 'PDL bindings to some BLAS and LAPACK library routines',
  AUTHOR => [ 'Chris Marshall <chm@cpan.org>' ],
  VERSION_FROM => 'lib/PDL/LinearAlgebra.pm',
  LICENSE => 'artistic_2',
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      homepage => 'http://pdl.perl.org/',
      repository  => {
        url => 'git://github.com/PDLPorters/pdl-linearalgebra.git',
        type => 'git',
        web => 'https://github.com/PDLPorters/pdl-linearalgebra',
      },
      bugtracker => {web=>'https://github.com/PDLPorters/pdl-linearalgebra/issues'},
    },
    x_IRC => 'irc://irc.perl.org/#pdl',
  },
  CONFIGURE_REQUIRES =>  {
    "Devel::CheckLib" => 0,
    "ExtUtils::F77" => 0,
    "PDL" => 0,
  },
  PREREQ_PM => { "PDL" => 0 },
  dist => { PREOP=>'$(PERL) -MPDL::Core::Dev -e pdlpp_mkgen $(DISTVNAME)' }, # GENERATED subdir in dist tarball
  clean => { FILES => '*~' },
);
