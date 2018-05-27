/**
 *  ElderlyAndPIRSensorSimulation
 *  Author: tlathanh
 *  Description: 
 */

model ElderlyAndPIRSensorSimulation

/* Insert your model definition here */

global {
	int nb_elderly <- 1;
    int nb_pir_sensors <- 4;
    
    // Map configs
    file map_init <- image_file("../images/home650502.png");
    grid_cell myCell <- grid_cell at {70.0,31.0}; 
    bool show_path <- false;  
           
    //PIR configs       
    list<pir_sensor> pir_sensor_list <- [];
    list<float> pir_start_angles <- [265.0, 175.0, 20.0, 45.0]; //degree
    list<float> pir_angles <- [110.0, 110.0, 110.0, 110.0]; //degree, should be  < 180 
    list<float> pir_ranges <- [20.0, 35.0, 35.0, 40.0]; 
    list<int> pir_signal <- [0,0,0,0];
    //PIR configs 
    
    // <-- Elderly Beahaviors
    float step <- 1 #seconds;
    //float step <- 1 #minute;
    int current_hour update: (time / #hour) mod 24;
    int current_minute update: (time / #mn) mod 60;
	float current_second update: (time / #seconds) mod 60;
	
    list<point> bath_room_points <- [point(42,11), point(53,7), point(38,13)];
    list<point> kitchen_points <- [point(8,7), point(6,37), point(51,33), point(23,25)];
    list<point> living_points <- [point(8,55), point(50,57),point(48,87),point(10,81),point(50,67)];
    list<point> bedroom_points <- [point(83,29), point(85,41),point(83,47),point(95,69),point(65,51)];
    list<string> liststatus <- ["sleeping", "cook", "pee", "sleeping", "cook",  "pee", "watch_movie",  "pee", "watch_movie","sleeping", "pee", "sleeping", "cook",  "pee", "watch_movie",  "pee", "watch_movie","sleeping", "pee", "sleeping", "cook",  "pee", "watch_movie",  "pee", "watch_movie"];
    bool no_more_action <- false;
    //  --> Elderly Beahaviors
    
    //Path finding
    list<grid_cell> openList <- [];
    list<grid_cell> closeList <- [];
     
    //Mouse click event
    action sensor_range_toogle (point loc, list selected_agents) {
      	ask selected_agents as: grid_cell {
			grid_cell target <- self;
			//write "fing path from" + myCell.grid_x + ":" + myCell.grid_y + " to " + target.grid_x + ":" +target.grid_y;	
			write "" + target.grid_x + ":" +target.grid_y;	
			write "location" + target.location;
      	}
    }
	
	reflex stop_simulation when: (current_hour >=23) and (current_minute >=59) and (current_second >= 59) or no_more_action {
        do halt ;
    } 
    
	reflex save_result when: (current_second mod 10) = 0 {
        loop i from: 0 to: length(pir_signal) -1 {
        	pir_signal[i] <- (pir_signal[i] > 1) ? 1 : 0; 
        }
        
        //save ("0 " + pir_signal[3] + " " + pir_signal[1] + " " + pir_signal[0] + " " + pir_signal[2] + " " +  first(elderly).status  +  "  " + "\"" +current_hour+":"+ current_minute +"\"")
        save ("0 " + pir_signal[3] + " " + pir_signal[1] + " " + pir_signal[0] + " " + pir_signal[2] + " " + "" +current_hour+":"+ current_minute + " " + first(elderly).location +"") 
        to: "simulation_logs.txt" type: "text" ;
        
        //reset pir signal to 0
        pir_signal <- [0,0,0,0]; 
    }
    
    init {
		create elderly number: nb_elderly;
		
		ask grid_cell {
			grid_cell current_cell <- self;
			color <- rgb(map_init at { grid_x, grid_y });
			
			// the wall is black
			if (color as list)[0] = 0 and (color as list)[1] = 0 and (color as list)[2] = 0 {
				isWall <- true;
			} // end of wall detected
			
			
			// PIR sensor is on the red points						
			if (color as list)[0] >= 255 and (color as list)[1] = 0 and (color as list)[2] = 0 {	
				is_sensor_location <-true;						
				
				create species(pir_sensor) {
					self.location <- current_cell.location;
					self.sensor_id <- length(pir_sensor_list);
					self.range <- pir_ranges[self.sensor_id];
					
					add self to: pir_sensor_list;
					
					write "sensor detected. id:" + self.sensor_id + " location: (" + self.location.x + " , " + self.location.y + ")";
				}
				
				current_cell.sensor_id <- length(pir_sensor_list) - 1;
			} // end of PIR sensor detected
		} // end of ask grid_cell for wall and sensor detection


		// Calculate sensor range of detection
		// Algorithm: find all the point in range of sensor and in the sector
		// reference: http://stackoverflow.com/questions/13652518/efficiently-find-points-inside-a-circle-sector
		ask pir_sensor_list {
			pir_sensor curretn_pir_sensor <- self;
			point curretn_pir_sensor_location <- curretn_pir_sensor.location;
			
			write "range detection for sensor:" + self.sensor_id + " location: (" + self.location.x + " , " + self.location.y + ")" + "range" + self.range;
			
			// Find all the cells:
			// 1. In range of detection
			// 2. In range of angle
			ask grid_cell {
				grid_cell current_cell <- self;
				
				
				float mX <- curretn_pir_sensor_location.x + pir_ranges[curretn_pir_sensor.sensor_id]*cos(-pir_start_angles[curretn_pir_sensor.sensor_id]);
				float mY <- curretn_pir_sensor_location.y + pir_ranges[curretn_pir_sensor.sensor_id]*sin(-pir_start_angles[curretn_pir_sensor.sensor_id]);
				
				float nX <- curretn_pir_sensor_location.x + pir_ranges[curretn_pir_sensor.sensor_id]*cos(-pir_start_angles[curretn_pir_sensor.sensor_id] + (180-pir_angles[curretn_pir_sensor.sensor_id]));
				float nY <- curretn_pir_sensor_location.y + pir_ranges[curretn_pir_sensor.sensor_id]*sin(-pir_start_angles[curretn_pir_sensor.sensor_id] + (180-pir_angles[curretn_pir_sensor.sensor_id]));
				
				float startArmX <- mX - curretn_pir_sensor_location.x; 
				float startArmY <- mY - curretn_pir_sensor_location.y;
				
				float endArmX <- nX - curretn_pir_sensor_location.x; 
				float endArmY <- nY - curretn_pir_sensor_location.y;
				
				// 1. If cell are in sensor range
				float distance_to_current_sensor <- (current_cell.location.x - curretn_pir_sensor.location.x)*(current_cell.location.x - curretn_pir_sensor.location.x) + (current_cell.location.y - curretn_pir_sensor.location.y)*(current_cell.location.y - curretn_pir_sensor.location.y);
				if (distance_to_current_sensor <= curretn_pir_sensor.range*curretn_pir_sensor.range) {
					
					// 2. If cell are in the range of angle
					float relPointX <- current_cell.location.x - curretn_pir_sensor_location.x;
					float relPointY <- current_cell.location.y - curretn_pir_sensor_location.y;
					
					bool areCounterClockWise <- false;
					if( ((-1)*startArmX*relPointY + startArmY*relPointX) > 0) {
						areCounterClockWise <- true;
					}
					
					bool areClockWise <- false;
					if(((-1)*endArmX*relPointY + endArmY*relPointX) > 0) {
						areClockWise <- true;
					}
					
					if(areCounterClockWise and areClockWise) {
						if (current_cell.isWall = true) {
							add current_cell to: curretn_pir_sensor.points_in_range_is_wall;
						} else {
							current_cell.color <- curretn_pir_sensor.color;
							add current_cell to: curretn_pir_sensor.points_in_range;
							current_cell.occupied_by_sensor[curretn_pir_sensor.sensor_id] <- true;
						}						
					}
				}
			}
		} //End of calculating sensor range of detection
		
		// Remove un-touched cells by sensor
		ask pir_sensor_list {
			pir_sensor current_sensor <- self;
			
			list<grid_cell> points_in_range <- current_sensor.points_in_range;
			list<grid_cell> points_in_range_is_wall <- current_sensor.points_in_range_is_wall;
			
			loop i from: 0 to: length (points_in_range) - 1 {
				loop j from: 0 to: length (points_in_range_is_wall) - 1 {
					float mX <- current_sensor.location.x - points_in_range_is_wall[j].location.x;
					float mY <- current_sensor.location.y - points_in_range_is_wall[j].location.y;
					
					float mX2 <- points_in_range[i].location.x - points_in_range_is_wall[j].location.x;
					float mY2 <- points_in_range[i].location.y - points_in_range_is_wall[j].location.y;
					
					if ((mX*mX2 <= 0) and (mY*mY2<=0)) {
						points_in_range[i].color <- #white;	
						j <- length (points_in_range_is_wall) + 1;
						points_in_range[i].occupied_by_sensor[current_sensor.sensor_id] <- false;
						//current_sensor.points_in_range[] >- i;
						//break;						
					}					
				}
			} 
		}	//Remove un-touched cells by sensor
		
		//Re-colored
		ask pir_sensor_list {
			rgb current_color <- self.color;
			int sensor_id <- self.sensor_id;			
			ask self.points_in_range {
				if (self.occupied_by_sensor[sensor_id]) {
					self.color <- current_color; 					
				}
			}			
		} 
		//End Re-colored
	}// End of init
}

species elderly skills: [moving] {
	float size <- 3.0;
	rgb color <- #blue;
	//float speed <- 3 #km / #h;
	float speed <- 0.02 °meter / °sec;
	point the_target <- nil;	
	
	list<point> pathToTarget <- [];
	point next_location <- nil;
	bool isMoving <- false;
	bool target_reached <- true;
	
	int hour <- 0;
    int minute <- 0;
	float second <- 0.0;
	
	int thour <- 0;
    int tminute <- 0;
	float tsecond <- 0.0;
		
	string status <- "";
	string old_status <- "undefined";

	init {
		location <- myCell.location;
	}
	
	reflex change_status when: target_reached and (current_hour >= thour) and (current_minute >= tminute) and (current_second >= tsecond) {
		if(liststatus!=nil and length(liststatus) > 0) {
			old_status <- status;
			status <- first(liststatus);
			remove status from: liststatus;	
			target_reached <- false;
			write "state changed" + old_status + "-> " + status;
		} else {
			no_more_action <- true;
			write "Stop simulation, no more action";
		}
	}
	
		
	reflex sleeping when: status = "sleeping" {
		if (!target_reached and !isMoving) {
			next_location <- one_of(bedroom_points);	
		}
		
		// sleep time
		hour <- 0;
		minute <- 2;
		second <- 0.0;
	}
	
	reflex pee when: status = "pee" {
		if (!target_reached and !isMoving) {
			next_location <- one_of(bath_room_points);	
		}
		
		hour <-  0;
		minute <- 1;
		second <- 0.0;
	}
	
	reflex cook when: status = "cook" {
		if (!target_reached and !isMoving) {
			next_location <- one_of(kitchen_points);	
		} 
		
		hour <-  0;
		minute <- 5;
		second <- 0.0;	
	}
	
	reflex watch_movie when: status = "watch_movie" {
		if (!target_reached and !isMoving) {
			next_location <- one_of(living_points);	
		}
		
		hour <-  0;
		minute <- 5;
		second <- 0.0;
	} 
	
	reflex move when: the_target != nil {
		isMoving <- true;
		target_reached <- false;
		
		heading <- (self towards the_target);
		do move speed: speed; 
		
		if ((location distance_to the_target) <= 1) {
			location <- the_target;			
		}
		
		grid_cell current_cell <- grid_cell at {location.x, location.y};
		loop i from: 0 to: length (current_cell.occupied_by_sensor) - 1 {
			if (current_cell.occupied_by_sensor[i] = true) {
				pir_signal[i] <- pir_signal[i] + 1;
				//write "sensor " + i + "trigger";
			}  
		}
		
		if (location = the_target) {
			if length(pathToTarget) > 0 {
				the_target <- last(pathToTarget);
				remove the_target from: pathToTarget;
			} else {
				the_target <- nil;
				isMoving <- false;

				target_reached <- true;
				
				//calculate time
				tsecond <- current_second + second;
				tsecond <- (tsecond > 59) ? 0 : tsecond;				
				int tmp <- (tsecond > 59) ? 1 : 0;
				
				tminute <- current_minute + minute + tmp;
				tminute <- (tminute > 59) ? 0 : tminute;
				tmp <- (current_minute > 59) ? 1 : 0;
				
				thour <- current_hour + hour + tmp;
				
				//write "" + thour + ":" + tminute + ":" + tsecond;
			}	
		}
	}
	
	// A* shortest path
	reflex find_path_to_target when: next_location != nil {
			pathToTarget <- [];
			ask grid_cell {
				self.g <- 0;
				self.h <- 0;
				self.f <- 0;
				
				self.came_from <- nil;
			}
			
			grid_cell target <- next_location;
			openList <- [];
			closeList <- [];
			
			myCell <- grid_cell at(location);
			
			add myCell to: openList;
			myCell.g <- 0.0;
			myCell.h <- myCell distance_to target;
			myCell.f <- target.g + target.h;
			bool path_founded <- false;
			
			loop while: (length(openList) > 0) {
				grid_cell current <- first(openList);
				
				//find small f in openlist
				ask openList {
					if (self.f < current.f) {
						current <- self;
					}					
				}
				
				if (current.grid_x = target.grid_x and current.grid_y = target.grid_y) {
					path_founded <- true;
					openList <- [];
					closeList <- [];
				} else {
					remove current from: openList;
					add current to: closeList;
					
					ask current.neighbours {
						if (!self.isWall) {
							if (! (closeList contains self)) {
								float tmp <- current.g + (current distance_to self);
								if (!(openList contains self) or tmp < self.g) {
									self.came_from <- current;
									self.g <- tmp;
									self.h <- self distance_to target;
									self.f <- self.g + self.h;
									if (!(openList contains self)) {
										add self to: openList;
									}
								}
							}
						}
					}
				}
			}// end of check open list, path not found
			
			next_location <- nil;
			
			//find path if found
			if (path_founded = true) {
				grid_cell t <- target;
				loop while: (!(t = nil)) {
					add t.location to: pathToTarget;
					if(show_path) {
						t.color <- #red;	
					}
					
					t <- t.came_from;
				}
				the_target <- last(pathToTarget);
			}
	}
			
	aspect base {
        draw circle(size) color: color ;
    }
}


//http://www.ladyada.net/media/sensors/PIRSensor-V1.2.pdf
// PIR_SENSOR range ~ 200 feet (6m)

// https://www.mpja.com/download/31227sc.pdf
// angle: 110
species pir_sensor {
	int sensor_id <- 0;
	float size <- 1.0;
	float range <- 10.0;
    //rgb color <- [100 + rnd (155),100 + rnd (155), 100 + rnd (155)] as rgb;
    rgb color <- [0, 128, 0] as rgb;
    list<grid_cell> points_in_range <- [];
	list<grid_cell> points_in_range_is_wall <- [];
	
    aspect base {
        draw circle(size) color: color ;
    }
}

grid grid_cell width: 53 height: 50 neighbours: 8 {
	bool isWall <- false;
	bool is_sensor_location <- false;
	int sensor_id <- 0;
	
	float g <- 0.0;
	float h <- 0.0;
	float f <- 0.0;
	grid_cell came_from <- nil;
	
	list<bool> occupied_by_sensor <- [false, false, false, false];
	list<grid_cell> neighbours <- self neighbours_at 1;
}


experiment elderly_pir_sensor_simulation type: gui {
    parameter "Initial number of Eldely: " var: nb_elderly min: 1 max: 1 category: "Elderly" ;
    output {
        display main_display {
        	grid grid_cell lines: #black;
            species elderly aspect: base ;
            species pir_sensor aspect: base ;
        }
    }
}


//Note:

// Calculate elderly speed based on the size of house
// Moving around to trigger pir signal when cook, watching movie or take a shower