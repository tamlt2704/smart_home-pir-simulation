/**
 *  ElderlyInSmartHome
 *  Author: tlathanh
 *  Description: 
 */

model ElderlyInSmartHome

/* Insert your model definition here */

global {
    int nb_eldelys_init <- 1;
    int nb_pir_sensors <- 4;
    int pir_range <- 10; 
     
    file map_init <- image_file("../images/home65050_copy.png");
    grid_cell myCell <- one_of (grid_cell);
    
    list<pir_sensor> pir_sensor_list <- [];
    list<float> pir_start_angles <- [265.0, 175.0, 45.0, 45.0]; //degree
    list<float> pir_angles <- [100.0, 120.0, 120.0, 120.0]; //degree, should be  < 180 
    list<float> pir_ranges <- [35.0, 35.0, 35.0, 35.0]; 
    bool sensor_can_not_sense_after_wall <- true;
    int i <- 1;
//    action change_shape (point loc, list selected_agents)
//    {
//       ask selected_agents as: grid_cell {
//      	//is_square <- not (is_square);
//      	self.color <- #white;
//      }
//    }
    	
//      action sensor_range_toogle (point loc, list selected_agents) {
//      	write loc;
//      	ask selected_agents as: grid_cell {
//      		self.color <- #red;
//      		write self.color;
//      	}
//      }
//    reflex save_result {
//        save ("cycle: "+ cycle + "; nbPreys: " + myCell.location)
//            to: "results.txt" type: "text" ;
//    }
    
    init {
        create elderly number: nb_eldelys_init ;
		
		list grid_cell_list <-list (species_of (grid_cell));
		
		// set the wall so eldely will not go out of the bound        
        ask grid_cell {
			color <- rgb (map_init at {grid_x,grid_y});
			
			// the wall is black
			if (color as list)[0] = 0 and (color as list)[1] = 0 and (color as list)[2] = 0 {
				isWall <- true;
			}
			
			grid_cell current_cell <- self;
			
			// PIR sensor is on the red points						
			if (color as list)[0] >= 255 and (color as list)[1] = 0 and (color as list)[2] = 0 {	
				isWall <-true;						
				isSensorLocation <- true;
				
				create species(pir_sensor) {
					self.location <- current_cell.location;								
					self.id <- i;
					add self to: pir_sensor_list;
					i <- i+1;
				}
			} 								 
		} //end of ask grid cell
		
		loop j from: 0 to: length (pir_sensor_list) - 1 {
			ask pir_sensor_list[j] {
				pir_sensor centerPoint <- pir_sensor_list[j];
				centerPoint.range <- pir_ranges[j];
				 
				point pcenter <- centerPoint.location;
				float mX <- pcenter.x + pir_ranges[j]*cos(-pir_start_angles[j]);
				float mY <- pcenter.y + pir_ranges[j]*sin(-pir_start_angles[j]);
				
				float nX <- pcenter.x + pir_ranges[j]*cos(-pir_start_angles[j] + (180-pir_angles[j]));
				float nY <- pcenter.y + pir_ranges[j]*sin(-pir_start_angles[j] + (180-pir_angles[j]));
				
				float startArmX <- mX - pcenter.x; 
				float startArmY <- mY - pcenter.y;
				
				float endArmX <- nX - pcenter.x; 
				float endArmY <- nY - pcenter.y;

				save ("O("+pcenter.x+","+pcenter.y+")" + " M("+mX+","+mY+")" + "N("+nX+","+nY+")") to: "results.txt" type: "text" ;
													
				ask grid_cell {
					float distanceToSensor <- (self.location.x - pcenter.x)*(self.location.x - pcenter.x) + (self.location.y - pcenter.y)*(self.location.y - pcenter.y);									
					if (distanceToSensor <= centerPoint.range*centerPoint.range) {   
						float relPointX <- self.location.x - pcenter.x;
						float relPointY <- self.location.y - pcenter.y;
						
						bool areCounterClockWise <- false;
						if( ((-1)*startArmX*relPointY + startArmY*relPointX) > 0) {
							areCounterClockWise <- true;
						}
						
						bool areClockWise <- false;
						if(((-1)*endArmX*relPointY + endArmY*relPointX) > 0) {
							areClockWise <- true;
						}
						
																			
						
						if(areCounterClockWise and areClockWise) {
							float cosToCenter <- relPointX*centerPoint.range / (sqrt(relPointX*relPointX + relPointY*relPointY)*sqrt(centerPoint.range*centerPoint.range));
							if(self.isWall) {
								add self to: pir_sensor_list[j].points_in_rage_is_wall;
								self.occupied_by_sensor[j] <- false;
								save ("wall collide self.location" +self.location.x+":"+self.location.y) to: "results.txt" type: "text" ;
								centerPoint.unTouchAngelDistance <+ distanceToSensor::cosToCenter;																
							} else {
								self.color <- centerPoint.color;
								self.occupied_by_sensor[j] <- true;
								add self to: pir_sensor_list[j].points_in_rage;	
							}
							
							self.distance_to_sensors[j] <- distanceToSensor;
							self.angleToSensor[j] <- acos(cosToCenter);
						}	
					}
				}
			}
		} //end of loop j
		
		//remove untouched cell
		//a(x1, y1), b(x2, y1)
		// y = k(x-x0) + y0,  k = (y2-y1)/(x2-x1)
		// d(M,delta) = |a.xo + b.y0 + c| / (sqrt(a*a + b*b)) 
		loop j from: 0 to: length (pir_sensor_list) - 1 {
			draw line([{10, 10},{20, 50}]) color: #red  empty: true;
			ask pir_sensor_list[j] {
				pir_sensor currentSensor <- pir_sensor_list[j];
				list<grid_cell> pointInRange <- currentSensor.points_in_rage;
				list<grid_cell> pointInRangeIsWall <- currentSensor.points_in_rage_is_wall;
				
				loop k from: 0 to: length (pointInRange) - 1 {
					ask pointInRange[k] {
//						float mK  <- (pointInRange[k].location.y - currentSensor.location.y) / (pointInRange[k].location.x - currentSensor.location.x);
//						float mC  <- (-1.0)*mK*currentSensor.location.x + currentSensor.location.y;
						 
						loop l from: 0 to: length (pointInRangeIsWall) - 1 {
							ask pointInRangeIsWall[l] {
								draw line([{currentSensor.location.x, currentSensor.location.y}, {pointInRangeIsWall[l].location.x, pointInRangeIsWall[l].location.y}]) color: #red;
								draw line([{10, 10},{20, 50}]) color: #green  empty: true;
//								float distanceToLine <- abs(mK*pointInRangeIsWall[l].location.x - pointInRangeIsWall[l].location.y + mC)/sqrt(mK*mK + 1);
//								save ("Distance to line" + distanceToLine) to: "results.txt" type: "text" ;
//								if (distanceToLine <= 4) {
//									pointInRange[k].color <- #white;
//								} 								
							}
						}
					}
				}
			}
		}
		//remove untouched cell		
		
    } //end of init
    
    
    
//    reflex stop_simulation when: (myCell.isWall) {
//        do halt ;
//    } 
}

species pir_sensor {
	int id <- 0; // sensor id: 1,2,3,4 -> bathroom, kitchen, living room, bed room
	float range <- 10.0;
	float size <- 1.0;
    rgb color <- [100 + rnd (155),100 + rnd (155), 100 + rnd (155)] as rgb;
    
	list<grid_cell> points_in_rage <- [];
	list<grid_cell> points_in_rage_is_wall <- [];
	map<float, float> unTouchAngelDistance <- [];
	
	reflex detect_movement {
		if self distance_to myCell < range {
			save ("people are in rage of" +self.id + "at" + self.location + "people location" + myCell.location) to: "results.txt" type: "text" ;
		} 
	}
		
	aspect base {
        draw circle(size) color: color ;
    }
}

species elderly {
	float size <- 3.0 ;
    rgb color <- #blue;
    
	init {
		location <- {25,35};//myCell.location;
		
	}
	
	reflex basic_move { 
		
       grid_cell tmpCell <- one_of (myCell.neighbours) ;
       
       if ! tmpCell.isWall {
       	 myCell <- tmpCell;
       } 
       
       location <- myCell.location ;
    }
    
    aspect base {
        draw circle(size) color: color ;        
    }
}

grid grid_cell width: 53 height: 50 neighbours: 8 {
	bool isWall <- false;
	bool isSensorLocation <- false;
	int inSensorRange <- 0;	
	float cosUV <- 0.0;
	
	list<bool> occupied_by_sensor <- [false, false, false, false];
	
	
	init {
		inSensorRange <- 0;
	}
	
	
	list<grid_cell> neighbours <- self neighbours_at 1;
	list<int> distance_to_sensors <- [0, 0, 0, 0];
	list<float> angleToSensor <- [0.0, 0.0, 0.0, 0.0];
}
experiment Elderly_in_smart_home type: gui {
    parameter "Initial number of Eldely: " var: nb_eldelys_init min: 1 max: 100 category: "Elderly" ;
    output {
        display main_display {
        	grid grid_cell lines: #black;
            species elderly aspect: base ;
            species pir_sensor aspect: base ;
            //event [mouse_down] action: sensor_range_toogle;
        }
    }
}