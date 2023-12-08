Most code are copied from mini.comment and SingleComment repo. Thanks for the great work.

# Motivation

I found most plugins that working with react are commenting on eaching line instead of just comment
on the first and last line when available.

SingleComment plugin seems working on it, but it fails to do so when comment on react files like,

```jsx
  render() {
    const a = 123;
    const b = 123;
    return (
      <div>
        <span>123</span>
        <span>123</span>
        <span>123</span>
        <span>123</span>
      </div>
    );
  }
```

what i want is like this,

```jsx
  render() {
    const a = 123;
    const b = 123;
    return (
      <div>
        <span>123</span>
        {/*<span>123</span>
           <span>123</span>
           <span>123</span>*/}
      </div>
    );
  }
```

while well, vscode is like this, no additional indent for the following lines

```jsx
  render() {
    const a = 123;
    const b = 123;
    return (
      <div>
        <span>123</span>
        {/* <span>123</span>
        <span>123</span>
        <span>123</span> */}
      </div>
    );
  }
```


instead of this,

```jsx
  render() {
    const a = 123;
    const b = 123;
    return (
      <div>
        <span>123</span>
        {/*<span>123</span>*/}
        {/*<span>123</span>*/}
        {/*<span>123</span>*/}
      </div>
    );
  }
```

Since i cannot found out why i cannot get the right comment string using ts_comment_string plugin,
I just copied this part of logic from mini.comment plugin.

## Test case

### back compatibale

if it's already formated like this, then comment on each line, since most plugins are using this kind of style

```jsx
      <div>
        <span>123</span>
        {/*<span>123</span>*/}
        {/*<span>123</span>*/}
        {/*<span>123</span>*/}
      </div>
```

### blank lines between lines

```jsx
    const a = 123;

    const b = 123;
```

### support inline comment

```jsx
function test(a, /*b*/, c) {}
```

### mutiline block

```jsx
  const qrCodeProps = {
    value,
    size: size - (token.paddingSM + token.lineWidth) * 2,
    level: errorLevel,
    bgColor,
    fgColor: color,
    imageSettings: icon ? imageSettings : undefined,
  };
```

## Goal

- [x] comment jsx when more than 1 line is selected no matter where the cursor is
- [ ] need test lua file multi-lines
- [ ] 发现vissual 打印不出来可能是被覆盖了，所以我直接写变量到全局，然后自己手动打印
- [x] see if i can unify just using original repo
- [x] add space after comment

## TODO

- [ ] can not print lua message when selecting multi-lines in visiual mode
- [x] single line toggle are not working right(right comment part missing, i guess it's because of toggle_lines impl, yes it is)
- [ ] support setup config(like disable, custom comment string)
- [x] json file comment not right like coc.json(yeah, actually json file type doesnt support comment)

## What not support

1. 10gc, ...

## Refs

1. [test](https://github.com/nvim-lua/plenary.nvim/blob/master/TESTS_README.md)
2. [mini.comment](https://github.com/echasnovski/mini.comment)
3. [my fork](https://github.com/CaryWill/SingleComment.nvim)
4. [lua guide](https://neovim.io/doc/user/lua-guide.html)

