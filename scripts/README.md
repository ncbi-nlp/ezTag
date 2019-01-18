# eztag.rb : a script for downloading/uploading 



## Install

1. Get your **apikey**: please contact the person with administrator's priviliges.

2. Replace the key in the apikey file(**./apikey**) with your own.

3. Install missing libraries

   ```shell
   gem install httparty
   ```

4. Grant execute permission to the script, if you need
   ```shell
   chmod +x ./eztag.rb
   ```


​    

## Run

```shell
./eztag.rb
```



## Usage

```
Usage: eztag.rb COMMAND [options] path (or files for upload)

Commands:
   u / upload      Upload BioC files in the path to user's collection
   d / download    Download documents in user's collection into the path

Options:
    -v, --[no-]verbose               Run verbosely
    -f, --[no-]force-upload          Upload duplicate documents even if they have the same PMID
    -H, --host=HOST                  Hostname for the server (default: eztag.bioqrator.org)
    -P, --port=PORT                  Port number for the server (default: 80)
    -k, --keyfile=KEY_FILE_PATH      API key file path (default: ./apikey)
    -u, --user=USER_EMAIL            User email
    -U, --user_id=USER_ID            User ID
    -c, --col=COLLECTION_NAME        Collection name
    -C, --col_id=COLLECTION_ID       Collection ID
    -r, --[no-]replace               Remove documents with the same doucment id before uploading

Common options:
    -h, --help                       Show this message
        --version                    Show version
```



## Examples

``` shell
# Upload a single file './test1/abc.xml' into a collection named 'A' of a user (user1@abc.com) 
./eztag.rb u -u user1@abc.com -c A ./test1/abc.xml

# Upload multiple files
./eztag.rb u -u user1@abc.com -c A ./test1/abc.xml ./test1/def.xml

# Upload files with a wildcard
./eztag.rb u -u user1@abc.com -c A ./test1/*
./eztag.rb u -u user1@abc.com -c A ./test1/a*.xml

# Upload all files in a directory (./test1) 
./eztag.rb u -u user1@abc.com -c A ./test1

# Duplicate(force) uploads with the same document id
./eztag.rb u -f -u user1@abc.com -c A ./test1/abc.xml

# Remove the existing one, and Upload the document
./eztag.rb u -f -r -u user1@abc.com -c A ./test1/abc.xml

# ------------------------------------------------------------------------

# Download all documents in a collection into a directory
./eztag.rb d -u user1@abc.com -c A ./output


```

