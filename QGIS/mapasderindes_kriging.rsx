##Shape=vector point
##Rinde=field Shape
##Poligono=vector polygon
##Distancia = number 40
##showplots
##output=output raster

#output_plots_to_html
##showplots


library(sp)
library(spdep)
library(gstat)

crs_imagen<-st_crs(Shape)
datos <- as_Spatial(Shape)
poligono <- as_Spatial(Poligono)

proj4string(datos) <- CRS(proj4string(datos))


>print("ARMO GRILLA DE MUESTREO")
grdpts <- makegrid(poligono, cellsize = 5)
spgrd <- SpatialPoints(grdpts, proj4string = CRS(proj4string(poligono)))
spgrdWithin <- SpatialPixels(spgrd[poligono,])
par(mfrow= c(1,1))
>plot(spgrdWithin,col = "red", pch = 10, cex = 0.2,xlab="X",ylab="Y")
gri<-spgrdWithin
print(str(gri))
print(CRS(proj4string(poligono)))

>print("ARMO VARIOGRAMA")
require(gstat)

semivariograma <- variogram(get(Rinde)~1, datos, cutoff=250)


sill<-max(semivariograma$gamma)
nugget<-semivariograma[1,3]
distancia<-max(semivariograma$dist)

error1 = 9999
modelo_final = "aaa"
seleccion_modelo<-function(){
	modelos<-c("Sph","Exp","Lin","Gau","Ste","Mat")
		for (i in 1:length(modelos)){
                print(i)
		modelovgm<- fit.variogram(semivariograma, fit.method=1, vgm(sill,modelos[i],distancia,nugget))
	 	error<-(attr(modelovgm , 'SSErr'))
			if(error < error1){
                        modelo_final <<- modelos[i]
		        error1<-error
 			print(modelo_final)	
			print(error1)	
                        }
            }
}

suppressWarnings(seleccion_modelo())
modelovgm<- fit.variogram(semivariograma, fit.method=1, vgm(sill,modelo_final,distancia,nugget))
plot(semivariograma,modelovgm ,main="",xlab="Distancia",ylab="Semivarianza")

data2<-remove.duplicates(datos)
>print("Datos originales")
>print(nrow(datos))
>print("Datos filtrados")
>print(nrow(data2))

crs(data2)<-NA
crs(gri)<-NA

Kg_wls <- krige(get(Rinde)~1, data2, gri, model = modelovgm, debug.level=-1,maxdist=40)

print("Armamos el Raster para ver en QGIS")
raster<- raster(Kg_wls,layer=1)
crs(raster)<-crs(poligono)
output <- raster