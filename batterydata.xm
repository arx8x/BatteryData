#include "PreferenceBundles/BatteryUsageUI.bundle/BatteryUIController.h"
#include "Preferences/PSSpecifier.h"
#include "IOKit/IOKitLib.h"


%hook BatteryUIController


%new
-(id) specifierWithName:(NSString *)name value:(NSString *)value isCopyable:(BOOL)isCopyable
{
	PSSpecifier *specifier = [%c(PSSpecifier) new];
	specifier.identifier = name;
	specifier.name = name;
	specifier.target = self;
	[specifier setProperty:value forKey:@"value"];
	[specifier setProperty:[NSNumber numberWithBool:isCopyable] forKey:@"isCopyable"];
	specifier.cellType = 4;
	return specifier;
}


-(id) specifiers
{
  NSMutableArray *specifiers = %orig;

  NSMutableDictionary *pData = [NSMutableDictionary new];
  CFMutableDictionaryRef pdict = IOServiceMatching("IOPMPowerSource");
  io_service_t powerservice = IOServiceGetMatchingService(kIOMasterPortDefault, pdict);

  CFMutableDictionaryRef powerData;
  kern_return_t pret = IORegistryEntryCreateCFProperties(powerservice, &powerData, 0, 0);

  if(pret == KERN_SUCCESS)
  {
    pData = (__bridge NSMutableDictionary*)powerData;
    // [[[UIAlertView alloc] initWithTitle:@"Alert" message:[NSString stringWithFormat:@"%@", batteryData] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
  }

  if([pData count])
	{
    [specifiers addObject:[PSSpecifier groupSpecifierWithName:@"Battery information"]];
		NSLog(@"got powerData");

		NSMutableString* batteryCapacity = [[NSMutableString alloc] init];
		if([pData objectForKey:@"AppleRawMaxCapacity"] != nil)
		{
			[batteryCapacity appendString:[NSString stringWithFormat:@"%@", [pData objectForKey:@"AppleRawMaxCapacity"]]];
			NSLog(@"added AppleRawMaxCapacity");
		}
		if([pData objectForKey:@"DesignCapacity"] != nil)
		{
			[batteryCapacity appendString:[NSString stringWithFormat:@" / %@", [pData objectForKey:@"DesignCapacity"]]];
			NSLog(@"added DesignCapacity");
		}
		if([[batteryCapacity stringByTrimmingCharactersInSet:[NSCharacterSet  whitespaceCharacterSet]] length] != 0)
		{
			[batteryCapacity appendString:@" mAh"];
			NSLog(@"append mah");
		}
		[specifiers addObject:[self specifierWithName:@"Battery Capacity" value:batteryCapacity isCopyable:TRUE]];
		if([pData objectForKey:@"AppleRawMaxCapacity"] && [pData objectForKey:@"DesignCapacity"])
		{
			double percentage = ([((NSNumber *)[pData objectForKey:@"AppleRawMaxCapacity"]) floatValue] / [((NSNumber *)[pData objectForKey:@"DesignCapacity"]) floatValue]) * 100;
			NSString *batteryHealth = [NSString stringWithFormat:@"%.2f%%", percentage];
			[specifiers addObject:[self specifierWithName:@"Battery Health" value:batteryHealth isCopyable:TRUE]];
		}

		NSLog(@"added capacity data");

		if([pData objectForKey:@"Serial"] != nil)
		{
			[specifiers addObject:[self specifierWithName:@"Battery Serial" value:[NSString stringWithFormat:@"%@", [pData objectForKey:@"Serial"]] isCopyable:TRUE]];
			NSLog(@"added battery serial");
		}

    if([pData objectForKey:@"Model"] != nil)
    {
      [specifiers addObject:[self specifierWithName:@"Battery Model" value:[NSString stringWithFormat:@"%@", [pData objectForKey:@"Model"]] isCopyable:TRUE]];
      NSLog(@"added battery model");
    }

		if([pData objectForKey:@"Temperature"] != nil)
		{
			[specifiers addObject:[self specifierWithName:@"Temperature" value:[NSString stringWithFormat:@"%.1f °C", [(NSNumber *)[pData objectForKey:@"Temperature"] floatValue]/100] isCopyable:TRUE]];
			NSLog(@"added battery Temperature");
		}

    if([pData objectForKey:@"CycleCount"] != nil)
    {
      [specifiers addObject:[self specifierWithName:@"Battery Cycles" value:[NSString stringWithFormat:@"%@", [pData objectForKey:@"CycleCount"]] isCopyable:TRUE]];
      NSLog(@"added battery cycles");
    }

    if([pData objectForKey:@"InstantAmperage"] != nil)
    {
      [specifiers addObject:[self specifierWithName:@"Instant ameprage" value:[NSString stringWithFormat:@"%@ mA", [pData objectForKey:@"InstantAmperage"]] isCopyable:TRUE]];
      NSLog(@"added instant apmerage");
    }

    if([pData objectForKey:@"Voltage"] != nil)
    {
      [specifiers addObject:[self specifierWithName:@"Voltage" value:[NSString stringWithFormat:@"%.1fv", ([(NSNumber*)[pData objectForKey:@"Voltage"] floatValue])/1000] isCopyable:TRUE]];
      NSLog(@"added voltage");
    }


		if([[pData objectForKey:@"ExternalConnected"] boolValue])
		{
			NSLog(@"init Charger specs");
			NSDictionary* adaperInfo = [pData objectForKey:@"AdapterDetails"];
      NSMutableString *groupTitle = [NSMutableString stringWithString:@"Adapter Information"];
      if([adaperInfo objectForKey:@"Description"] != nil)
      {
        [groupTitle appendFormat:@"(%@)", [adaperInfo objectForKey:@"Description"]];
      }
      [specifiers addObject:[PSSpecifier groupSpecifierWithName:groupTitle]];
      [specifiers addObject:[self specifierWithName:@"Max Voltage" value:[NSString stringWithFormat:@"%.1fv", ([(NSNumber*)[adaperInfo objectForKey:@"AdapterVoltage"] floatValue])/1000] isCopyable:TRUE]];
      // [specifiers addObject:[self specifierWithName:@"Charging Voltage" value:[NSString stringWithFormat:@"%.1fv", ([(NSNumber*)[chargerData objectForKey:@"ChargingVoltage"] floatValue])/1000] isCopyable:TRUE]];
      [specifiers addObject:[self specifierWithName:@"Max Current" value:[NSString stringWithFormat:@"%.1fA", ([(NSNumber*)[adaperInfo objectForKey:@"Amperage"] floatValue])/1000] isCopyable:TRUE]];
      // [specifiers addObject:[self specifierWithName:@"Charging Current" value:[NSString stringWithFormat:@"%.1fA", ([(NSNumber*)[chargerData objectForKey:@"ChargingCurrent"] floatValue])/1000] isCopyable:TRUE]];
      [specifiers addObject:[self specifierWithName:@"Max Power" value:[NSString stringWithFormat:@"%@w", [adaperInfo objectForKey:@"Watts"]] isCopyable:TRUE]];
      // [specifiers addObject:[self specifierWithName:@"Drawing Power" value:[NSString stringWithFormat:@"%.2fw", ( ([(NSNumber*)[chargerData objectForKey:@"ChargingVoltage"] floatValue]) * ([(NSNumber*)[chargerData objectForKey:@"ChargingCurrent"] floatValue]) )/1000000] isCopyable:TRUE]];
			NSLog(@"Charger specs done, added");


		}
	}

  return specifiers;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  PSTableCell *cell = (PSTableCell *)[tableView cellForRowAtIndexPath:indexPath];
  if([NSStringFromClass([cell class]) isEqualToString:@"PSGraphViewTableCell"])
  {
    [self showInternalViewController];
  }
  %orig;
}


- (id)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  PSTableCell *cell = %orig;
  if([NSStringFromClass([cell class]) isEqualToString:@"PSTableCell"])
  {
    PSSpecifier *specifier = cell.specifier;
    [specifier description];
    if(specifier.identifier)
    {
      if(![[cell value] length])
      {
        [cell setValue:[specifier propertyForKey:@"value"]];
      }
    }
  }
  return cell;
}



// -(BOOL)showDaemonsInInternal
// {
//   return TRUE;
// }


-(BOOL)shouldShowTime
{
  return TRUE;
}


-(int)batteryUIType
{
  return 2;
}

// -(int)batteryUIQueryType
// {
//   return 4;
// }


-(BOOL)showSaveDemoButtonInInternal
{
  return TRUE;
}

-(BOOL)shoudDisplayBugSignatures
{
  return TRUE;
}

%end





%ctor
{
  dlopen("/System/Library/PreferenceBundles/BatteryUsageUI.bundle/BatteryUsageUI", RTLD_LAZY);
}
