# Gemini diff script - gmidiff.sh

Bash script able to get content of valid Gemini protocol address, compute a hash of content and compare it with a earlier saved hash. Script can store multiple addresses. During add and update commands script compares hashes of the content. If configure command has been done, and e-mail address has been set, and content changed, script will sent diff via e-mail, in other case script will print diff on standard output.  

## Configuration files

* "$HOME/.config/gmidiff" or "$XDG_CONFIG_HOME/gmidiff"

### File format

Every address is stored in _.address.gmidiff_ file.

Every file is build as:
* one line of hash
* one line of adress
* many lines of content (only headlines _#_, _##_, _###_ and links _=>_)

### Dependencies

* sendmail
* openssl
* sha256sum
* sed 
* diff

### Usage

* gmidiff.sh add url - add a new Geminispace address, e.g.:
* gmidiff.sh add geminispace.info/backlinks?szczezuja.space
* gmidiff.sh configure - set configuration information 
* gmidiff.sh update - update previously added adresses
* gmidiff.sh reset - remove all previously added adresses
* gmidiff.sh help - print this help
