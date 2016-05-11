# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}
#
# THE FOLLOWING DISCLAIMER APPLIES TO ALL SOFTWARE CODE AND OTHER MATERIALS
# CONTRIBUTED IN CONNECTION WITH THIS PROGRAM.
#
# THIS SOFTWARE IS LICENSED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE AND ANY WARRANTY OF NON-INFRINGEMENT, ARE
# DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
# OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. THIS
# SOFTWARE MAY BE REDISTRIBUTED TO OTHERS ONLY BY EFFECTIVELY USING
# THIS OR ANOTHER EQUIVALENT DISCLAIMER AS WELL AS ANY OTHER LICENSE
# TERMS THAT MAY APPLY.
#

declaration template components/download/schema;

include { "quattor/schema" };

type component_download_file = {
    "href"    : string
    "post"    ? string
    "proxy"   : boolean = true
    "gssapi"  ? boolean
    "perm"    ? string
    "owner"   ? string
    "group"   ? string
    "min_age" : long = 0     # Don't consider the remote file to be new until it is this number of minutes old
    "cacert"  ? string
    "capath"  ? string
    "cert" ? string
    "key" ? string
    "timeout" ? long # seconds, overrides setting in component
};

type component_download_type = extensible {
    include structure_component
    "server" ? string
    "proto"  ? string with match(SELF, "https?")
    "files"  ? component_download_file{}
    "proxyhosts" ? string[]
    "head_timeout" ? long # seconds, timeout for HEAD requests which checks for changes
    "timeout" ? long # seconds, total timeout for fetch of file, can be overridden per file
};

bind "/software/components/download" = component_download_type;

