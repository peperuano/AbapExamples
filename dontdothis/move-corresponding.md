Move-Corresponding
==================

I had been asked by a customer to modify an existing report to account for new functionality. The functionality involved extending an existing process to fit some new types of variables. The customer however asked that the existing functionality remained as is.

## The Keyword

`move-corresponding` is specific in ABAP which is meant to assign components which share the same data element, domain, and name to be assigned easily to each other in one statement. 

```abap
form tc_items_modify.
	" The purpose of this function by the customer was to retreive
	" material data based on the material numbers that were
	" passed to it via an ABAP screen
	move-corresponding zbapisditm to g_tc_items_wa.
	" ... "
endform.
```

I don't know the structure of `ZBAPISDITM` or `G_TC_ITEMS_WA` at this point. I can quickly find them by double clicking on their names in the ABAP workbench.

```abap
types: begin of zbapisditm,
		" there are 201 columns
	   end of zbapisditm.
```

This `Z` structure in particular is a copy of a standard SAP structure provided with the SD software module. In this case, the structure had to be extended to allow for an article description to be sent along with it.

Next I investigate what `G_TC_ITEMS_WA` is, and what I see is:

```abap
data: g_tc_items_wa type zbapisditm.
```

`ZAPISDITEM` and `G_TV_ITEMS_WA` have exactly the same structure. In which case, `move-corresponding` is redudant and can be replaced by `=`.

```abap
gc_tc_items_wa = zbapisditm. " Same type of row
```

The issues which `move-corresponding` cause though aren't directly observable while using it, they cause issues for other developers down the line.

## Design Issue

Even though in the example `g_tc_items_wa` and `zbapisditm` have the same structure, considering what the situation would have been like if they didn't.

* `zbapisditm` is a copy of a standard SAP structure and has 201 columns.
* `zbapisditm` is only used in 1 report on the customer system, here.
* The developer is only making use of 7 out of the 201 different columns.
* `zbapisditm` and `g_tc_items_wa` are in the global scope and are both filled with the same properties.
* Data is syncronized between `zbapisditm` and `g_tc_items_wa`, even though they're both visible. 

The glaring issue isn't something that specific to ABAP either. When developers makes use of such keywords there are only a few things that be concluded.

* The consultant was lazy and didn't feel like manually mapping 201 parameters.
* The design was not considered or picked up from an incorrective perspective. If more than 90% of the components in the structure aren't being used than they did not properly come to understand the scope and context of the program.

## Technical Issue

The first question when using `move-corresponding` is what exactly is going to happen, because who actually knows. 

* The safest place to begin making any kind of assumption is if the two have a different structure **they're not compatible** and should **never be treated as if they are compatible**. Metaphorically speaking its like trying to fit a USB thumb drive into a CD tray.
* Assume `g_tc_items_wa` was a different structure that shared the same names. Data Elements, Domains have to also be considered. Even if the domains or data elements share the same basic type, `move-corresponding` won't work and you could be missing data you'd need later.
* Modifications and upgrades can change the results of `move-corresponding`, which means upgrades can cause incompatibility in later versions.
