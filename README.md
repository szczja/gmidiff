# Gemini diff script - gmidiff.sh

Bash script able to get content of valid Gemini protocol address, compute a hash of content and compare it with a earlier saved hash. Script can store multiple addresses. Script sends mail with a new content to $USER@localhost.

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

### Usage

* gmidiff.sh add url - add a new Geminispace address, e.g.:
* gmidiff.sh add geminispace.info/backlinks?szczezuja.space
* gmidiff.sh update - update previously added adresses
* gmidiff.sh reset - remove all previously added adresses
* gmidiff.sh help - print this help
