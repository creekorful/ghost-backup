# ghost-backup

Homemade bash script to back up a Ghost instance on S3.

## Usage

Using it is as simple as running:

```bash
$ ./ghost-backup.sh /var/www/blog.example.org/
```

## Requirements

### Runtime

In order to work properly this script must be run as the same user who owns the Ghost instance.

### Packages

This script require the following binaries to be installed.

- jq (provided by the [jq](https://tracker.debian.org/pkg/jq) package)
- aws (provided by [awscli](https://tracker.debian.org/pkg/awscli) package)
- mysqldump (provided by [mariadb-client](https://tracker.debian.org/pkg/mysql-client) package)

## Configuration

In order to be able to upload to S3 one must configure ghost-backup and aws cli. 

### awscli

The base aws cli configuration can be done by following [the official guide](https://docs.aws.amazon.com/cli/latest/reference/configure/).

### ghost-backup

In order to specify the s3 endpoint url and bucket to use one can create a configuration file for ghost-backup.

The configuration file must be located at `~/.config/ghost-backup.json`.

Here is an example configuration file:

```json
{
  "/var/www/blog.example.org/": {
    "aws": {
      "endpoint": "https://s3.us-west-000.backblazeb2.com",
      "bucket": "blog-example-org",
      "directory": ""
    }
  }
}
```