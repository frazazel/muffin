script "muffin.ash";
// written by frazazel (ign: SketchySolid) v2022-07-07
// type "muffin help" into KoLmafia's GCLI for usage instructions

boolean boolean_property(string str) { return to_boolean(get_property(str)); }
item item_property(string str)       { return to_item(get_property(str)); }

string join_strings(string[int] strs, string glue) {
// joins a bunch of strings into a single string, ignoring empty strings
	buffer buff;
	foreach i,s in strs {
		if(length(buff) != 0 && (length(s) != 0))
			buff.append(glue);
		buff.append(s);
	}
	return to_string(buff);
}

buffer run_choice(string buttontext, boolean runfight, string cfilter) {
	// runs a choice by selecting a button with text as specified.
	int choice = -1;
	string ltext = to_lower_case(buttontext);
	foreach i, str in available_choice_options() {
		if(contains_text(to_lower_case(str), ltext)) {
			if(choice == -1) {
				choice = i;
			} else {
				print("ERROR: choice adventure contains multiple buttons containing choice \""+buttontext+"\"","red");
				buffer buff;
				return buff; //run_choice(choice, runfight, cfilter); //This should probably error instead of warn.
			}
		}
	}
	return run_choice(choice, runfight, cfilter);
}
buffer run_choice(string buttontext, string cfilter)   { return run_choice(buttontext, true, cfilter); }
buffer run_choice(string buttontext, boolean runfight) { return run_choice(buttontext, runfight, ""); }
buffer run_choice(string buttontext)                   { return run_choice(buttontext, true, ""); }

item collect_muffin() {
	// collects a muffin from the monorail breakfast counter if available
	// assumes that mafia may be missing muffin order information, but if it's present, then assume it is correct.
	// tries to fetch a muffin in case there's one there, unless you already ordered a muffin today.
	item moo = item_property("muffinOnOrder");
	
	if(boolean_property("_muffinOrderedToday")) {
		print("Your order for a ["+moo+"] will be ready for pickup tomorrow.","orange");
		return $item[none];
	}
	
	int[item] qty;
	foreach it in $items[blueberry muffin,chocolate chip muffin,bran muffin,earthenware muffin tin] {
		qty[it] = item_amount(it);
	}
	visit_url("place.php?whichplace=monorail&action=monorail_downtown");
	run_choice("breakfast counter");
	run_choice("back to the platform");
	run_choice("nevermind");
	
	foreach it in $items[blueberry muffin,chocolate chip muffin,bran muffin,earthenware muffin tin] {
		if(item_amount(it) > qty[it]) {
			if(it == moo)
				print("Collected a(n) ["+it+"].","blue");
			else
				print("Collected a(n) ["+it+"], but we expected to collect "+(moo==$item[none]?"nothing":"a(n) ["+moo+"]")+".","orange");
			return it;
		}
	}
	
	print("There is no muffin ready for pickup!","orange");
	return $item[none];
}

boolean order_muffin(item muff) {
	// orders a new muffin from the monorail breakfast counter
	// if it detects that there is a muffin already on order, it will abort and alert the user
	// tries not to accidentally pick up a muffin that isn't specifically called to be collected, but 
	//   can fail at this if mafia's state is out of sync with KoL.
	item moo = item_property("muffinOnOrder");
	if(!boolean_property("_muffinOrderedToday")) {
		if(0 < item_amount($item[earthenware muffin tin]) || moo == $item[earthenware muffin tin]) {
			if(moo == $item[none] || moo == $item[earthenware muffin tin]) {
				buffer page = visit_url("place.php?whichplace=monorail&action=monorail_downtown");
				run_choice("breakfast counter");
				run_choice(to_string(muff));
				run_choice("back to the platform");
				run_choice("nevermind");
				if(boolean_property("_muffinOrderedToday") && item_property("muffinOnOrder") == muff) {
					print("Placed an order for a ["+muff+"]!","black");
					return true;
				} else { // ran muffin ordering script, but muffinOnOrder is not set as expected
					print("Tried to order a ["+muff+"], but something went wrong.","red");
					return false;
				}
			} else { // there is a muffin on order already, but it wasn't placed today
				print("Collect your ["+moo+"] first.","orange");
				return false;
			}
		} else { // no empty muffin tin in inventory or ready for pickup.
			print("No muffin tin available!","orange");
			return false;
		}
	} else { //if a muffin was already ordered today
		if(moo == muff) {
			print("You already ordered a ["+muff+"] today.","black");
			return true;
		} else {
			print("You already ordered a ["+moo+"] today.","orange");
			return false;
		}
	}
	//print("Something went wrong with your muffin order.","red");
	return false;
}

item to_muffin(string muff) {
	item it = $item[none];
	switch(to_lower_case(muff)) {
		case "blue":
		case "blueberry":
		case "blueberry muffin":
		case "1":
		case "meat":
		case "hp":
			it = $item[blueberry muffin];
			break;
		case "choc":
		case "chocolate":
		case "chocolate chip":
		case "chocolate chip muffin":
		case "2":
		case "both":
			it = $item[chocolate chip muffin];
			break;
		case "bran":
		case "bran muffin":
		case "3":
		case "items":
		case "mp":
			it = $item[bran muffin];
			break;
		default:
			print("Error: \""+muff+"\" is not a recognized muffin order.","red");
	}
	return it;
}

void print_help(boolean verbose) {
	item moo = item_property("muffinOnOrder");
	
	print("muffin - help | collect | [order] blue|choc|bran - manage muffins from the monorail breakfast counter","black");
	if(verbose) {
		print("accepts the following aliases for each muffin type:");
		print("blueberry muffin,blue,blueberry,1,meat,hp");
		print("chocolate chip muffin,choc,chocolate,chocolate chip,2,both");
		print("bran muffin,bran,3,items,mp");
	}
	
	if(boolean_property("_muffinOrderedToday")) {
		print("You have already ordered a ["+moo+"] for tomorrow. Come back after rollover!", "green");
	} else {
		if(moo != $item[none]) {
			print("You have a(n) ["+moo+"] ready for pickup now!","blue");
		} else if(0 < item_amount($item[earthenware muffin tin])) {
			print("The breakfast counter is ready to take your order!","blue");
		} else
			print("You don't have an [earthenware muffin tin]!","orange");
	}
}

void main(string blarg){
	string[int] args = split_string(blarg, " ");
	string command = remove args[0];
	item muff;

	switch(to_lower_case(command)) {
		case "order":
		case "prep":
		case "request":
			muff = to_muffin(join_strings(args," "));
			if(muff != $item[none]) {
				order_muffin(muff);
			} else {
				print_help(false);
			}
			break;
		case "collect":
		case "pickup":
		case "grab":
			collect_muffin();
			break;
		case "":
		case "help":
			print_help(true);
			break;
		default:
		// if the command is not recognized, check to see if a muffin alias has been provided directly.
		// (e.g. "muffin chocolate chip" instead of "muffin order chocolate chip")
			muff = to_muffin(command);
			//doesn't actually check the remaining args, because anything after the first word doesn't change the order.
			if(muff != $item[none]) {
				order_muffin(muff);
			} else {
				print_help(false);
			}
	}
}

