# ValidateXML.h

Add `ValidateXML.h` into your win32-API-based C++ project to get a simple wrapper around the MSXML6 DLL-based XML processing interface.
Must add "additional dependencies" of `msxml6.lib` (MSXML library) and `comsuppw.lib` (COM library) to your project (VisualStudio2022: Properties > Configuration Properties > Linker > Input > Additional Dependencies, or equivalent)

(This is meant as a minimum viable product for fast initial development and usage in my other projects; it can be done better.)

## Synopsis

```
#include "ValidateXML.h"
#include <iostream>
int main()
{
	bool ret = ValidateXML::validate_xml(L"input.xml", L"input.xsd");
	std::cout << "input.xml:         " << ValidateXML::sGetValidationMessage() << std::endl;

	ret = ValidateXML::validate_xml(L"input-invalid.xml", L"input.xsd");
	std::cout << "input-invalid.xml: " << ValidateXML::sGetValidationMessage() << std::endl;

	return 0;
}
```

## Details

### `ValidateXML::validate_xml(std::wstring wsXmlFileName, std::wstring wsXsdFileName)`

Pass in wide-string (or `L"..."`) for the filenames for the XML file you want to check, and the XSD file you will be validating against.
Returns `true` on success, or `false` on failure.  Also sets an internal string message: see `sGetValidationMessage()` and `wsGetValidationMessage()`)

### `ValidateXML::sGetValidationMessage()`

Returns the `std::string` message describing whether the most recent validation passed or failed.

### `ValidateXML::wsGetValidationMessage()`

Returns the `std::wstring` message describing whether the most recent validation passed or failed.

## Notes

### E1696 on the `#import` line: cannot find `*.tlh` file

When you first add the `ValidateXML.h` to the project, IntelliSense will likely claim it cannot find the `*.tlh` file for one of the DLL.  

The required steps to get rid of that false error:
1. Make sure you have `#include "ValidateXML.h"` somewhere in the project, otherwise the TLH won't be generated on a build
2. **Build > Rebuild Solution** to make sure everything (including the TLH) is built
3. **Project > Rescan Solution** to have IntelliSense rescan and fix its error
   - Alternative: RightClick on the project in Solution Explorer, and select **Rescan Solution**
   - Alternative: **Tools > Options > Text Editor > C/C++ > Advanced > Browsing/Navigation section > Recreate Database = `True`**, then exit and restart VisualStudio

After that, the IntelliSense error should be gone.

## TODO

- [ ] Eventually, I should wrap it as a class, instead, so different validators can track states separately.
