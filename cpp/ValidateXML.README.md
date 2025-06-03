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

## TODO

- [ ] Eventually, I should wrap it as a class, instead, so different validators can track states separately.
