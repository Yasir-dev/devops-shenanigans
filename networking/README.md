- [Checking DNS Records](#checking-dns-records)
  - [A Record](#a-record)
  - [AAA Record](#aaa-record)
- [Checking if SSH is available](#checking-if-ssh-is-available)

## Checking DNS Records

### A Record

```
dig EXAMPLE.COM +noall +answer -t A
```

### AAA Record

```
dig EXAMPLE.COM +noall +answer -t AAAA
```

### Checking if SSH is available

```
nc -zv <server_ip_or_hostname> 22
```

### Reverse DNS Lookup (PTR Record)

Find the domain name associated with an IP address.

´´´
dig -x 192.0.2.1
´´´

### Query CNAME Records

´´´
dig example.com CNAME
´´´

### Get Authoritative Name Servers (NS Records)

´´´
dig example.com NS
´´´

### View SOA Record for DNS Zone Information

´´´
dig example.com SOA
´´´

### View MX record

´´´
dig example.com MX +noall +answer
´´´

### View TXT record

dig example.com TXT +noall +answer
