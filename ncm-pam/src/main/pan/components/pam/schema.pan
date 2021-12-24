# ${license-info}
# ${developer-info}
# ${author-info}

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
################################################################################
# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

declaration template components/pam/schema;

include 'quattor/schema';

type pam_component_options = extensible {
};

type pam_component_listfile_acl = {

    "filename" : string
    "items" : string[]
};

type pam_component_module_stack = {
    "control" : string with match(SELF, '^(requisite|required|optional|sufficient|[^=]+=[^=]+(\s+[^=]+=[^=]+)*)$')
    "module" : string
    "options" ? pam_component_options
    "options_list" ? string[]
    "allow" ? pam_component_listfile_acl
    "deny" ? pam_component_listfile_acl
};

type pam_component_service_type = {
    "auth" ? pam_component_module_stack[]
    "account" ? pam_component_module_stack[]
    "password" ? pam_component_module_stack[]
    "session" ? pam_component_module_stack[]
    "mode" ? string with match(SELF, "0[0-7][0-7][0-7]")
};

type pam_component_module = {
    "path" ? string
};

# see pam_access(8)

type pam_component_access_entry = {
    "permission" : string with match(SELF, "^[-+]$")
    "users" : string
        "origins" : string
};

type pam_component_access = {
    "filename" : string
    "acl" : pam_component_access_entry[]
    "lastacl" : pam_component_access_entry
    "allowpos" : boolean
    "allowneg" : boolean
};

type pam_component = {
    include       structure_component
    "modules" ? pam_component_module{}
    "services" ? pam_component_service_type{}
    "directory" ? string
    "acldir" ? string
    "access" ? pam_component_access{}
};
