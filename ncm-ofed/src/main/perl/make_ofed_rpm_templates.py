#!/usr/bin/python

"""
SDW 2011/02/24

Make a local build of all OFED rpms
- run this script 
-- produces a directory <releasever> with 4 tpl files
--- rpms.tpl, devel.tpl, debuginfo.tpl and static.tpl
- should be added to the common/ofed/rpms
"""
import re,sys,os

deb=True

def log(txt):
    print "INFO %s"%txt
    
def error(txt):
    print "ERROR: %s"%txt

def debug(txt):
    if deb:
        print "DEBUG %s"%txt
    
def usage():
    print """
    Creates 4 tpl files: rpms.tpl, devel.tpl, debuginfo.tpl and kernel.tpl
    
    Options:
        -r    Release name
        
        -s    RPMs source dir
        
        -h    Print this help
    """
    sys.exit(0)

def getrpms(p):
    """
    p is path
    """
    import glob
    
    rpms=[ os.path.basename(x) for x in glob.glob("%s/*.rpm"%p) if os.path.isfile(x)]
    
    if len(rpms) == 0:
        error("No rpms found in %s"%p)
    
    processlist=['static','debuginfo','devel','mpi','rpms']
    mpiregexp=re.compile('(mpi|mvapich|mpich)')
    res={}
    for pr in processlist:
        res[pr]=[]
        
    for rpm in rpms:
        tmp=rpm.split('.')
        arch=tmp[-2]
        fullname='.'.join(tmp[:-2]).split('-')
        vidx=[x[0].isdigit() for x in fullname].index(True)
        version='-'.join(fullname[vidx:])
        name='-'.join(fullname[:vidx])
        
        added=False

        if (not added) and mpiregexp.search(name):
            res['mpi'].append([name,version,arch])
            added=True
            debug("Added to %s: %s"%('mpi',[name,version,arch]))
        
        for pr in processlist[:-2]:
            if (not added) and ( pr in fullname[:vidx]):
                res[pr].append([name,version,arch])
                added=True
                debug("Added to %s: %s"%(pr,[name,version,arch]))
        if not added:
            res['rpms'].append([name,version,arch])
            debug("Added to rpms: %s"%([name,version,arch]))
        
    
    return res

def maketpltxt(title,release,rpms,defarch='x86_64'):
    head="""unique template common/ofed/rpms/%s/%s;

variable PKG_ARCH_OFED ?= PKG_ARCH_DEFAULT;

"""%(release,title)

    pkgs=''
    kernelvar=''

    rpms.sort()

    for r in rpms:
        name='"%s"'%r[0]
        version='"%s"'%r[1]
        arch='"%s"'%r[2]
        if arch == '"%s"'%defarch:
            arch='PKG_ARCH_OFED'

        if r[0].startswith('kernel'):
            vs=r[1].split('-')
            kernelvar='variable PKG_KERNEL_OFED ?= "%s";\n\n'%vs[-1]
            version='"%s-"+PKG_KERNEL_OFED'%'-'.join(vs[:-1])
            
            
        pkgs+="'/software/packages' = pkg_repl(%s,%s,%s);\n"%(name,version,arch)
    
    return head+kernelvar+pkgs

def maketpls(allrpms,release):
    releasedir=os.path.join(os.getcwd(),release)
    if not os.path.exists(releasedir):
        os.makedirs(releasedir)
    for k,v in allrpms.items():
        tlp=maketpltxt(k,release,v)
        try:
            f=open(os.path.join(releasedir,"%s.tpl"%k),'w')
            f.write(tlp)
            f.close()
        except Exception, err:
            error("Failed to write file %s to dir %s:%s"%(releasedir,k,err))
        
    log("Wrote templates to %s"%releasedir)

if __name__ == '__main__':
    """
    Collect all info
    """
    import getopt
    allopts = ["help"]

    release=None
    srcdir=os.getcwd()
    try:
        opts,args = getopt.getopt(sys.argv[1:], "hr:s:", allopts)
    except getopt.GetoptError,err:
        print "\n" + str(err)
        usage()
    
    for key, value in opts:
        if key in ("-h", "--help"):
            usage()

        if key in ("-r"):
            release=value
        
        if key in ("-s"):
            try:
                srcdir=os.path.abspath(value)
            except Exception, err:
                error("Failed to get abspath of sourcedir %s"%value)
                sys.exit(1)
            if not os.path.isdir(srcdir):
                error("srcdir %s is not a directory"%srcdir)
                sys.exit(2) 
                
    if not release:
        error("No release specified.")
        usage()
    log("Release %s"%release)
    log("RPM source dir %s"%srcdir)
    
    rpms=getrpms(srcdir)
    
    maketpls(rpms,release)
    