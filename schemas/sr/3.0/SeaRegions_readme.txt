-----------------------------------------------------------------------------------------------------
European Commission Joint Research Centre 2014-03-24

=== Sea Reagion XML Schema relaese final version 3.0 ===
Version 3.0 of SeaRegions.xsd has a dependency on the "Hydro - Physical Waters" schema (http://inspire.ec.europa.eu/schemas/hy-p/), since it refers to the element hy-p:Shore and type hy-p:ShoreType. 

In the Annex II+III amendment of the Implementing Rules on interoperability of spatial data sets and services, this element and type have been modified slightly, which will require an update of the "Hydro - Physical Waters" schema. This update is currently being discussed in the INSPIRE Maintenance and Implementation Group.

Version 3.0 of SeaRegions.xsd will therefore be published together with the updated schemas for the "Hydro - Physical Waters" package.

=== Changes from v3.0rc3 to v3.0 ===
The following changes will be made when publishing version 3.0 of the SeaRegions.xsd schema:

1.
<import namespace="urn:x-inspire:specification:gmlas:HydroPhysicalWaters:3.0" schemaLocation="http://inspire.ec.europa.eu/schemas/hy-p/3.0/HydroPhysicalWaters.xsd"/>

will be updated to the namespace and schemaLocation of the updated "Hydro - Physical Waters" schema.

2.
<element name="InterTidalArea" type="sr:InterTidalAreaType" substitutionGroup="sr:SeaArea">

will be changed to

<element name="InterTidalArea" type="sr:InterTidalAreaType" substitutionGroup="hy-p:Shore">

3.
<complexType name="InterTidalAreaType">
  <complexContent>
    <extension base="sr:SeaAreaType">

will be changed to

<complexType name="InterTidalAreaType">
  <complexContent>
    <extension base="hy-p:ShoreType">


=== Contact ===
inspire-info@jrc.ec.europa.eu

-----------------------------------------------------------------------------------------------------
