//! gpui-pre's tests mark some functions with zed's `#[perf]`. Outside zed they only
//! need to run as plain tests.

use proc_macro::TokenStream;

/// Turns the function into a `#[test]`.
#[proc_macro_attribute]
pub fn perf(_attribute: TokenStream, item: TokenStream) -> TokenStream {
    let mut test: TokenStream = "#[test]".parse().expect("`#[test]` is valid Rust");
    test.extend(item);
    test
}
