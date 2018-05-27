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
    list<float> pir_start_angles <- [265, 175, 90, 45]; //degree
    list<float> pir_angles <- [120, 120, 120, 120]; //degree, should be  < 180 
    list<float> pir_ranges <- [29, 25, 20, 25]; 
    int i <- 1;
    
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
					//save ("Create pir_sensor id:" + self.id + "at" + self.location + "i=" + i) to: "results.txt" type: "text" ;
										
					add self to: pir_sensor_list;
					
					//save ("pir_sensor list" + pir_sensor_list ) to: "results.txt" type: "text" ;
					i <- i+1;
				}
			} 								 
		}
		
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
					
					//if (self.location distance_to centerPoint.location < centerPoint.range) {
														
					if ((self.location.x - pcenter.x)*(self.location.x - pcenter.x) + (self.location.y - pcenter.y)*(self.location.y - pcenter.y) <= centerPoint.range*centerPoint.range) {   
						
					
						
								
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
						
//						if (self.location.x = mX and self.location.y = mY) {
//							self.color <- #red;
//						}
						if(areCounterClockWise and areClockWise) {
							
//							float uX <- self.location.x - pcenter.x;
//							float uY <- self.location.y - pcenter.y;
//							
//							float vX <- centerPoint.range;
//							float vY <- pcenter.y;
//							float cosUV <- (uX*vX + uY*vY) / (sqrt(uX*uX + uY*uY)*sqrt(vX*vX+vY*vY));
//							
//							save ("VALID POINT"+self.location.x+":"+self.location.y +"cos"+cosUV) to: "results.txt" type: "text" ;
//							self.cosUV <- cosUV;

							
							if(self.isWall) {
								add self to: pir_sensor_list[j].points_in_rage_is_wall;
								save ("wall collide self.location"+self.location.x+":"+self.location.y) to: "results.txt" type: "text" ;																
							} else {
								self.color <- centerPoint.color;
								add self to: pir_sensor_list[j].points_in_rage;	
							}
						}	
					}
				}
			}
		}
		
//		loop j from: 0 to: length (pir_sensor_list) - 1 {
//			pir_sensor current_sensor <- pir_sensor_list[j];			
//			loop k from: 0 to: length (current_sensor.points_in_rage) - 1 {
//				grid_cell point_in_range <- current_sensor.points_in_rage;
//				ask current_sensor.points_in_rage_is_wall {
//					if ((self.location.x-current_sensor.location.x)*(self.location.x-point_in_range.location.x) < 0) {
//						self.color <- #white;
//					}
//					if ((self.location.y-current_sensor.location.y)*(self.location.y-point_in_range.location.y) < 0) {
//						self.color <- #white;
//					}
//				}	
//			}			
//		}
		
		/*ask grid_cell {
			int distance_to_sensor <- 0;
			
			loop j from: 0 to: length (pir_sensor_list) - 1 {
				if (pir_sensor_list[j].location distance_to self.location < pir_ranges[j]) {
					point pcenter <- pir_sensor_list[j].location;
						
					float mX <- pcenter.x + pir_ranges[j]*cos(pir_start_angles[j]);
					float mY <- pcenter.y + pir_ranges[j]*sin(pir_start_angles[j]);
					float nX <- pcenter.x + pir_ranges[j]*cos(pir_start_angles[j] + pir_angles[j]);
					float nY <- pcenter.y + pir_ranges[j]*sin(pir_start_angles[j] + pir_angles[j]);
					
					float startArmX <- mX - pcenter.x; 
					float startArmY <- mY - pcenter.y;
					
					float endArmX <- nX - pcenter.x; 
					float endArmY <- nY - pcenter.y;
					
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
						self.color <- #red;	
					}					
				}
										
				self.distance_to_sensors[j] <- (pir_sensor_list[j].location distance_to self.location);
			}
			
			//self.inSensorRange <- distance_to_sensor;
		}*/
		
		// check if a point inside a circle sector
		//http://stackoverflow.com/questions/13652518/efficiently-find-points-inside-a-circle-sector
		
//		loop i from: 0 to: length (grid_cell_list) - 1 {
//			 ask grid_cell_list at i { 
//				 	loop j from: 0 to: length (pir_sensor_list) - 1 {
//					if (pir_sensor_list[j].location distance_to self.location < pir_range) {
//						self.inSensorRange <- j;
//					} 
//				}
//			 }
//		}
    }
    
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
	init {
		inSensorRange <- 0;
	}
	
	
	list<grid_cell> neighbours <- self neighbours_at 1;
	list<int> distance_to_sensors <- [0, 0, 0, 0];	
}
experiment Elderly_in_smart_home type: gui {
    parameter "Initial number of Eldely: " var: nb_eldelys_init min: 1 max: 100 category: "Elderly" ;
    output {
        display main_display {
        	grid grid_cell lines: #black;
            species elderly aspect: base ;
            species pir_sensor aspect: base ;
        }
    }
}