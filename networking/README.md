
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
