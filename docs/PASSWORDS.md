# Password Generation

`New-PGenRandomPassword` generates cryptographically secure random passwords using configurable character sets and cryptographically strong random number generation.

The function supports:

- Uppercase letters
- Lowercase letters
- Numbers
- Special characters
- Minimum numeric requirements
- Minimum special character requirements
- Ambiguous character exclusion
- Clipboard support
- SecureString output
- Metadata output

---

## How It Works

Passwords are generated using:

```text
System.Security.Cryptography.RandomNumberGenerator
```

The function:

1. Builds the enabled character sets.
2. Generates required characters for each enabled set.
3. Generates additional characters from the combined character pool.
4. Applies a cryptographically secure Fisher-Yates shuffle.
5. Returns the final password.

This approach guarantees that minimum requirements are always satisfied.

---

## Default Behavior

```powershell
New-PGenRandomPassword
```

Default settings:

```text
Length     = 16
Uppercase  = True
Lowercase  = True
Numbers    = True
Special    = True
```

Example:

```text
gE@8Qw2m#aY6Tz3L
```

By default, the generated password contains at least:

- One uppercase letter
- One lowercase letter
- One number
- One special character

---

## Password Length

Specify a custom password length:

```powershell
New-PGenRandomPassword `
    -Length 24
```

Example:

```text
v#P2zD@8JmQ4x!Ra7Lk%T9Wc
```

---

## Character Sets

### Uppercase Letters

Enable or disable uppercase characters:

```powershell
New-PGenRandomPassword `
    -Uppercase:$false
```

### Lowercase Letters

Enable or disable lowercase characters:

```powershell
New-PGenRandomPassword `
    -Lowercase:$false
```

### Numbers

Enable or disable numeric characters:

```powershell
New-PGenRandomPassword `
    -Numbers:$false
```

### Special Characters

Enable or disable special characters:

```powershell
New-PGenRandomPassword `
    -Special:$false
```

---

## Character Set Examples

### Lowercase and Numbers Only

```powershell
New-PGenRandomPassword `
    -Uppercase:$false `
    -Lowercase:$true `
    -Numbers:$true `
    -Special:$false `
    -Length 16
```

Example:

```text
k4zj9tw1v0qs6m7c
```

### Uppercase Only

```powershell
New-PGenRandomPassword `
    -Uppercase:$true `
    -Lowercase:$false `
    -Numbers:$false `
    -Special:$false `
    -Length 16
```

Example:

```text
HQZWJCVBKTRMPXDS
```

### Numbers Only

```powershell
New-PGenRandomPassword `
    -Uppercase:$false `
    -Lowercase:$false `
    -Numbers:$true `
    -Special:$false `
    -Length 16
```

Example:

```text
3814602759801142
```

---

## Minimum Numeric Requirements

Specify the minimum number of digits required.

```powershell
New-PGenRandomPassword `
    -Length 20 `
    -MinimumNumbers 3
```

Example:

```text
sW7$yM8@Qa2LrTg%XpHu
```

At least three numeric characters are guaranteed.

A positive value automatically enables numeric characters.

---

## Minimum Special Character Requirements

Specify the minimum number of special characters required.

```powershell
New-PGenRandomPassword `
    -Length 20 `
    -MinimumSpecial 2
```

Example:

```text
sW7@yM8!Qa2LrTgXpHuV
```

At least two special characters are guaranteed.

A positive value automatically enables special characters.

---

## Combined Minimum Requirements

```powershell
New-PGenRandomPassword `
    -Length 24 `
    -MinimumNumbers 4 `
    -MinimumSpecial 3
```

Example:

```text
Qw7$Er4@Ty2!Ui8Op3As6DfG
```

The generated password will always satisfy the specified requirements.

---

## Ambiguous Character Exclusion

Use `-NoAmbiguousCharacters` to exclude characters that are commonly confused.

Excluded characters:

```text
Uppercase:
    I
    O

Lowercase:
    l

Numbers:
    0
    1
```

Example:

```powershell
New-PGenRandomPassword `
    -NoAmbiguousCharacters
```

Possible output:

```text
tG@8Qw2m#aY6Tz3L
```

---

## Custom Special Characters

The default special-character set is:

```text
!@#$%^&*
```

You may provide your own set:

```powershell
New-PGenRandomPassword `
    -SpecialCharacters '_+-='
```

Example:

```text
cF_8pA=qM+1zL-rN
```

Duplicate special characters are automatically removed.

---

## Metadata Output

Use `-PassThruObject` to return password metadata.

```powershell
New-PGenRandomPassword `
    -Length 24 `
    -MinimumNumbers 2 `
    -MinimumSpecial 2 `
    -PassThruObject
```

Example:

```text
Password                : Tm!4qN3@Lc2hRw8#Jf6DpXaK
Length                  : 24
ContainsUppercase       : True
ContainsLowercase       : True
ContainsNumbers         : True
ContainsSpecial         : True
UppercaseCount          : 8
LowercaseCount          : 9
NumberCount             : 4
SpecialCount            : 3
MinimumNumbers          : 2
MinimumSpecial          : 2
AmbiguousCharsExcluded  : False
CharacterPoolSize       : 70
PoolBasedEntropyBits    : 147.09
CopiedToClipboard       : False
```

---

## Character Pool Size

The default character pool contains:

```text
Uppercase    26
Lowercase    26
Numbers      10
Special       8
----------------
Total        70
```

When ambiguous characters are excluded:

```text
Uppercase removed  2
Lowercase removed  1
Numbers removed    2
--------------------
Total removed      5
```

Resulting pool size:

```text
65
```

---

## Entropy

A pool-based entropy estimate is included in metadata output.

Approximate calculation:

```text
PasswordLength × log₂(CharacterPoolSize)
```

Example:

```text
16 characters, pool size 70
≈ 98.1 bits
```

```text
24 characters, pool size 70
≈ 147.1 bits
```

The value is intended as a comparative estimate rather than an absolute measurement.

---

## Clipboard Support

Copy the generated password to the clipboard:

```powershell
New-PGenRandomPassword `
    -CopyToClipboard
```

The password is still returned to the pipeline.

---

## SecureString Output

Return the password as a SecureString:

```powershell
New-PGenRandomPassword `
    -AsSecureString
```

Output type:

```text
System.Security.SecureString
```

---

## Examples

### Default Password

```powershell
New-PGenRandomPassword
```

Example:

```text
gE@8Qw2m#aY6Tz3L
```

### Longer Password

```powershell
New-PGenRandomPassword `
    -Length 32
```

Example:

```text
Wx8@Pq2!Lm6#Rt4%Yu7&Io3$As9*Df*G
```

### Avoid Ambiguous Characters

```powershell
New-PGenRandomPassword -NoAmbiguousCharacters
```

Example:

```text
vT@8Qw2m#aY6Tz3L
```

### Specifying Custom Special Characters

```powe*shell
New-PGenRandomPassword `
   -SpecialCharacters '_+-='
```

Exa*ple:

```text
E_8Qw2*+aY6Tz=L
```

### Metadata Output (PassThruObject)

```powers*ell
New-PGenRandomPassword `
    -PassThruObject
```

Returns a PSCustomObject containing*password statistics and generation metadata.

---

## Validation Rule

The function prevents invalid configurations.

### Invalid (All character sets disabled)

All character sets disabled:

```powers*ell
New-PGenRandomPassword `
    -Uppercase:$false `
    -Lowercase:$false `
    -Numbers:$false `
    -Special:$false
```

### Invalid (Password length shorter)

Password length shorter than required minimums:

```powershell
New-PGenRandomPassword `
    -Length 4 `
    -MinimumNumbers 3 `
    -MinimumSpecial 3
```

### Invalid (Conflicting output)

Conflicting output types:

```powershell
New-PassGenRandomPassword `
    -AsSecureString `
    -PassThruObject
```

---

## Notes

### Cryptographically Secure Randomness

The function uses `System.Security.Cryptography.RandomNumberGenerator` instead of `Get-Random` for password generation.

### Automatic Character Set Enablement

The following automatically enable their corresponding character sets:

```powershell
-MinimumNumbers
-MinimumSpecial
```

Example:

```powershell
New-PGenRandomPassword `
    -Numbers:$false `
    -MinimumNumbers 3
```

*Numeric characters will still be included because a minimum requirement was specified.*
